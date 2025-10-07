# frozen_string_literal: true

module DockerMCP
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
