# frozen_string_literal: true

require 'json'
require 'open3'

module DockerMCP
  class PushImage < MCP::Tool
    description 'Push a Docker image'

    input_schema(
      properties: {
        name: {
          type: 'string',
          description: 'Image name or ID to push'
        },
        tag: {
          type: 'string',
          description: 'Tag to push (optional, pushes all tags if not specified)'
        },
        repo_tag: {
          type: 'string',
          description: 'Full repo:tag to push (e.g., "registry/repo:tag") (optional)'
        }
      },
      required: ['name']
    )

    def self.call(name:, server_context:, tag: nil, repo_tag: nil)
      # Construct the full image identifier
      image_identifier = tag ? "#{name}:#{tag}" : name

      # Validate that the image name includes a registry/username
      # Images without a registry prefix will fail to push to Docker Hub
      unless name.include?('/') || repo_tag&.include?('/')
        error_msg = 'Error: Image name must include registry/username ' \
                    "(e.g., 'username/#{name}'). Local images cannot be " \
                    'pushed without a registry prefix.'
        return MCP::Tool::Response.new([{
                                         type: 'text',
                                         text: error_msg
                                       }])
      end

      # Verify the image exists
      begin
        Docker::Image.get(image_identifier)
      rescue Docker::Error::NotFoundError
        return MCP::Tool::Response.new([{
                                         type: 'text',
                                         text: "Image #{image_identifier} not found"
                                       }])
      end

      # Use the Docker CLI to push the image
      # This way we leverage Docker's native credential handling
      push_target = repo_tag || image_identifier
      _, stderr, status = Open3.capture3('docker', 'push', push_target)

      if status.success?
        MCP::Tool::Response.new([{
                                  type: 'text',
                                  text: "Image #{push_target} pushed successfully"
                                }])
      else
        # Extract the error message from stderr
        error_msg = stderr.strip
        error_msg = 'Failed to push image' if error_msg.empty?

        MCP::Tool::Response.new([{
                                  type: 'text',
                                  text: "Error pushing image: #{error_msg}"
                                }])
      end
    rescue StandardError => e
      MCP::Tool::Response.new([{
                                type: 'text',
                                text: "Error pushing image: #{e.message}"
                              }])
    end
  end
end
