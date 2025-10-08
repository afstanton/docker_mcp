# frozen_string_literal: true

module DockerMCP
  PULL_IMAGE_DEFINITION = ToolForge.define(:pull_image) do
    description 'Pull a Docker image'

    param :from_image,
          type: :string,
          description: 'Image name to pull (e.g., "ubuntu" or "ubuntu:22.04")'

    param :tag,
          type: :string,
          description: 'Tag to pull (optional, defaults to "latest" if not specified in from_image)',
          required: false

    execute do |from_image:, tag: nil|
      # If tag is provided separately, append it to from_image
      # If from_image already has a tag (contains :), use as-is
      # Otherwise default to :latest
      image_with_tag = if tag
                         "#{from_image}:#{tag}"
                       elsif from_image.include?(':')
                         from_image
                       else
                         "#{from_image}:latest"
                       end

      image = Docker::Image.create('fromImage' => image_with_tag)

      "Image #{image_with_tag} pulled successfully. ID: #{image.id}"
    rescue Docker::Error::NotFoundError
      "Image #{image_with_tag} not found"
    rescue StandardError => e
      "Error pulling image: #{e.message}"
    end
  end

  PullImage = PULL_IMAGE_DEFINITION.to_mcp_tool
end
