# frozen_string_literal: true

require 'tool_forge'

module DockerMCP
  BUILD_IMAGE_DEFINITION = ToolForge.define(:build_image) do
    description 'Build a Docker image'

    param :dockerfile,
          type: :string,
          description: 'Dockerfile content as a string'

    param :tag,
          type: :string,
          description: 'Tag for the built image (e.g., "myimage:latest")',
          required: false

    execute do |dockerfile:, tag: nil|
      # Build the image
      image = Docker::Image.build(dockerfile)

      # If a tag was specified, tag the image
      if tag
        # Split tag into repo and tag parts
        repo, image_tag = tag.split(':', 2)
        image_tag ||= 'latest'
        image.tag('repo' => repo, 'tag' => image_tag, 'force' => true)
      end

      response_text = "Image built successfully. ID: #{image.id}"
      response_text += ", Tag: #{tag}" if tag
      response_text
    rescue StandardError => e
      "Error building image: #{e.message}"
    end
  end

  BuildImage = BUILD_IMAGE_DEFINITION.to_mcp_tool
end
