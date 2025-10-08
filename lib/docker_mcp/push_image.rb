# frozen_string_literal: true

require 'tool_forge'
require 'open3'

module DockerMCP
  PUSH_IMAGE_DEFINITION = ToolForge.define(:push_image) do
    description 'Push a Docker image'

    param :name,
          type: :string,
          description: 'Image name or ID to push'

    param :tag,
          type: :string,
          description: 'Tag to push (optional, pushes all tags if not specified)',
          required: false

    param :repo_tag,
          type: :string,
          description: 'Full repo:tag to push (e.g., "registry/repo:tag") (optional)',
          required: false

    execute do |name:, tag: nil, repo_tag: nil|
      # Construct the full image identifier
      image_identifier = tag ? "#{name}:#{tag}" : name

      # Validate that the image name includes a registry/username
      unless name.include?('/') || repo_tag&.include?('/')
        next 'Error: Image name must include registry/username ' \
             "(e.g., 'username/#{name}'). Local images cannot be " \
             'pushed without a registry prefix.'
      end

      # Verify the image exists
      begin
        Docker::Image.get(image_identifier)
      rescue Docker::Error::NotFoundError
        next "Image #{image_identifier} not found"
      end

      # Use the Docker CLI to push the image
      push_target = repo_tag || image_identifier
      _, stderr, status = Open3.capture3('docker', 'push', push_target)

      if status.success?
        "Image #{push_target} pushed successfully"
      else
        error_msg = stderr.strip
        error_msg = 'Failed to push image' if error_msg.empty?
        "Error pushing image: #{error_msg}"
      end
    rescue StandardError => e
      "Error pushing image: #{e.message}"
    end
  end

  PushImage = PUSH_IMAGE_DEFINITION.to_mcp_tool
end
