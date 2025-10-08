# frozen_string_literal: true

module DockerMCP
  # MCP tool for copying files and directories to Docker containers.
  #
  # This tool provides the ability to copy files and directories from the
  # local host filesystem into running Docker containers. It supports both
  # individual files and entire directory trees, with optional ownership
  # modification within the container.
  #
  # == Features
  #
  # - Copy files and directories from host to container
  # - Supports recursive directory copying
  # - Preserves file permissions and metadata
  # - Optional ownership modification after copy
  # - Works with running containers
  # - Comprehensive error handling and validation
  #
  # == Security Considerations
  #
  # File copying operations have significant security implications:
  # - **File System Access**: Reads local host file system content
  # - **Container Modification**: Alters container file system state
  # - **Data Injection**: Can introduce malicious files into containers
  # - **Permission Escalation**: May affect container security context
  # - **Resource Consumption**: Large copies can consume storage and I/O
  # - **Path Traversal**: Improper paths could access unintended locations
  #
  # **Security Recommendations**:
  # - Validate and sanitize all file paths
  # - Implement access controls for source file locations
  # - Monitor file copy operations and sizes
  # - Use read-only mounts where possible
  # - Apply resource limits to prevent abuse
  #
  # == Parameters
  #
  # - **id**: Container ID or name (required)
  # - **source_path**: Path to file/directory on local filesystem (required)
  # - **destination_path**: Path inside container for copied content (required)
  # - **owner**: Owner for copied files (optional, e.g., "1000:1000" or "username:group")
  #
  # == Example Usage
  #
  #   # Copy single file
  #   response = CopyToContainer.call(
  #     server_context: context,
  #     id: "web-server",
  #     source_path: "/local/config.conf",
  #     destination_path: "/etc/nginx/nginx.conf"
  #   )
  #
  #   # Copy directory with ownership change
  #   response = CopyToContainer.call(
  #     server_context: context,
  #     id: "app-container",
  #     source_path: "/local/app-data",
  #     destination_path: "/var/lib/app",
  #     owner: "app:app"
  #   )
  #
  # @see Docker::Container#archive_in_stream
  # @since 0.1.0
  COPY_TO_CONTAINER_DEFINITION = ToolForge.define(:copy_to_container) do
    description 'Copy a file or directory from the local filesystem into a running Docker container. ' \
                'The source path is on the local machine, and the destination path is inside the container.'

    param :id,
          type: :string,
          description: 'Container ID or name'

    param :source_path,
          type: :string,
          description: 'Path to the file or directory on the local filesystem to copy'

    param :destination_path,
          type: :string,
          description: 'Path inside the container where the file/directory should be copied'

    param :owner,
          type: :string,
          description: 'Owner for the copied files (optional, e.g., "1000:1000" or "username:group")',
          required: false

    # Helper method for adding files/directories to tar
    class_helper :add_to_tar do |tar, path, archive_path|
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

    execute do |id:, source_path:, destination_path:, owner: nil|
      container = Docker::Container.get(id)

      # Verify source path exists
      next "Source path not found: #{source_path}" unless File.exist?(source_path)

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
      response_text
    rescue Docker::Error::NotFoundError
      "Container #{id} not found"
    rescue StandardError => e
      "Error copying to container: #{e.message}"
    end
  end

  CopyToContainer = COPY_TO_CONTAINER_DEFINITION.to_mcp_tool
end
