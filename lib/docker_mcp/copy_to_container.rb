# frozen_string_literal: true

module DockerMCP
  # MCP tool for copying files and directories from host to Docker containers.
  #
  # This tool provides the ability to copy files or entire directory trees from
  # the host filesystem into running Docker containers. It uses Docker's archive
  # streaming API to efficiently transfer files while preserving permissions and
  # directory structure.
  #
  # == ⚠️ SECURITY WARNING ⚠️
  #
  # This tool can be dangerous as it allows:
  # - Reading arbitrary files from the host filesystem
  # - Writing files into container filesystems
  # - Potentially overwriting critical container files
  # - Escalating privileges if used with setuid/setgid files
  # - Exposing sensitive host data to containers
  #
  # Security recommendations:
  # - Validate source paths to prevent directory traversal
  # - Ensure containers run with minimal privileges
  # - Monitor file copy operations for sensitive paths
  # - Use read-only filesystems where possible
  # - Implement proper access controls on source files
  #
  # == Features
  #
  # - Copy individual files or entire directories
  # - Preserve file permissions and directory structure
  # - Optional ownership changes after copy
  # - Comprehensive error handling
  # - Support for both absolute and relative paths
  #
  # == Example Usage
  #
  #   # Copy a configuration file
  #   CopyToContainer.call(
  #     server_context: context,
  #     id: "web-server",
  #     source_path: "/host/config/nginx.conf",
  #     destination_path: "/etc/nginx/"
  #   )
  #
  #   # Copy directory with ownership change
  #   CopyToContainer.call(
  #     server_context: context,
  #     id: "app-container",
  #     source_path: "/host/app/src",
  #     destination_path: "/app/",
  #     owner: "appuser:appgroup"
  #   )
  #
  # @see Docker::Container#archive_in_stream
  # @since 0.1.0
  class CopyToContainer < MCP::Tool
    description 'Copy a file or directory from the local filesystem into a running Docker container. ' \
                'The source path is on the local machine, and the destination path is inside the container.'

    input_schema(
      properties: {
        id: {
          type: 'string',
          description: 'Container ID or name'
        },
        source_path: {
          type: 'string',
          description: 'Path to the file or directory on the local filesystem to copy'
        },
        destination_path: {
          type: 'string',
          description: 'Path inside the container where the file/directory should be copied'
        },
        owner: {
          type: 'string',
          description: 'Owner for the copied files (optional, e.g., "1000:1000" or "username:group")'
        }
      },
      required: %w[id source_path destination_path]
    )

    # Copy files or directories from host filesystem to a Docker container.
    #
    # This method creates a tar archive of the source path and streams it into
    # the specified container using Docker's archive API. The operation preserves
    # file permissions and directory structure. Optionally, ownership can be
    # changed after the copy operation completes.
    #
    # The source path must exist on the host filesystem and be readable by the
    # process running the MCP server. The destination path must be a valid path
    # within the container.
    #
    # @param id [String] container ID or name to copy files into
    # @param source_path [String] path to file/directory on host filesystem
    # @param destination_path [String] destination path inside container
    # @param server_context [Object] MCP server context (unused but required)
    # @param owner [String, nil] ownership specification (e.g., "user:group", "1000:1000")
    #
    # @return [MCP::Tool::Response] success/failure message with operation details
    #
    # @raise [Docker::Error::NotFoundError] if container doesn't exist
    # @raise [StandardError] for file system or Docker API errors
    #
    # @example Copy configuration file
    #   response = CopyToContainer.call(
    #     server_context: context,
    #     id: "nginx-container",
    #     source_path: "/etc/nginx/sites-available/default",
    #     destination_path: "/etc/nginx/sites-enabled/"
    #   )
    #
    # @example Copy directory with ownership
    #   response = CopyToContainer.call(
    #     server_context: context,
    #     id: "app-container",
    #     source_path: "/local/project",
    #     destination_path: "/app/",
    #     owner: "www-data:www-data"
    #   )
    #
    # @see Docker::Container#archive_in_stream
    # @see #add_to_tar
    def self.call(id:, source_path:, destination_path:, server_context:, owner: nil)
      container = Docker::Container.get(id)

      # Verify source path exists
      unless File.exist?(source_path)
        return MCP::Tool::Response.new([{
                                         type: 'text',
                                         text: "Source path not found: #{source_path}"
                                       }])
      end

      # Create a tar archive of the source
      tar_io = StringIO.new
      tar_io.set_encoding('ASCII-8BIT')

      Gem::Package::TarWriter.new(tar_io) do |tar|
        add_to_tar(tar, source_path, File.basename(source_path))
      end

      tar_io.rewind

      # Copy to container
      container.archive_in_stream(destination_path) do
        tar_io.read
      end

      # Optionally change ownership
      if owner
        chown_path = File.join(destination_path, File.basename(source_path))
        container.exec(['chown', '-R', owner, chown_path])
      end

      file_type = File.directory?(source_path) ? 'directory' : 'file'
      response_text = "Successfully copied #{file_type} from #{source_path} to #{id}:#{destination_path}"
      response_text += "\nOwnership changed to #{owner}" if owner

      MCP::Tool::Response.new([{
                                type: 'text',
                                text: response_text
                              }])
    rescue Docker::Error::NotFoundError
      MCP::Tool::Response.new([{
                                type: 'text',
                                text: "Container #{id} not found"
                              }])
    rescue StandardError => e
      MCP::Tool::Response.new([{
                                type: 'text',
                                text: "Error copying to container: #{e.message}"
                              }])
    end

    # Recursively add files and directories to a tar archive.
    #
    # This helper method builds a tar archive by recursively traversing
    # the filesystem starting from the given path. It preserves file
    # permissions and handles both files and directories appropriately.
    #
    # For directories, it creates directory entries in the tar and then
    # recursively processes all contained files and subdirectories.
    # For files, it reads the content and adds it to the tar with
    # preserved permissions.
    #
    # @param tar [Gem::Package::TarWriter] the tar writer instance
    # @param path [String] the filesystem path to add to the archive
    # @param archive_path [String] the path within the tar archive
    #
    # @return [void]
    #
    # @example Add single file
    #   add_to_tar(tar_writer, "/host/file.txt", "file.txt")
    #
    # @example Add directory tree
    #   add_to_tar(tar_writer, "/host/mydir", "mydir")
    #
    # @see Gem::Package::TarWriter#mkdir
    # @see Gem::Package::TarWriter#add_file_simple
    def self.add_to_tar(tar, path, archive_path)
      if File.directory?(path)
        # Add directory entry
        tar.mkdir(archive_path, File.stat(path).mode)

        # Add directory contents
        Dir.entries(path).each do |entry|
          next if ['.', '..'].include?(entry)

          full_path = File.join(path, entry)
          archive_entry_path = File.join(archive_path, entry)
          add_to_tar(tar, full_path, archive_entry_path)
        end
      else
        # Add file
        File.open(path, 'rb') do |file|
          tar.add_file_simple(archive_path, File.stat(path).mode, file.size) do |tar_file|
            IO.copy_stream(file, tar_file)
          end
        end
      end
    end
  end
end
