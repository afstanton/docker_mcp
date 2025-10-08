# frozen_string_literal: true

require 'tool_forge'

module DockerMCP
  TAG_IMAGE_DEFINITION = ToolForge.define(:tag_image) do
    description 'Tag a Docker image'

    param :id,
          type: :string,
          description: 'Image ID or current name:tag to tag'

    param :repo,
          type: :string,
          description: 'Repository name (e.g., "username/imagename" or "registry/username/imagename")'

    param :tag,
          type: :string,
          description: 'Tag for the image (default: "latest")',
          required: false,
          default: 'latest'

    param :force,
          type: :boolean,
          description: 'Force tag even if it already exists (default: true)',
          required: false,
          default: true

    execute do |id:, repo:, tag: 'latest', force: true|
      image = Docker::Image.get(id)

      image.tag('repo' => repo, 'tag' => tag, 'force' => force)

      "Image tagged successfully as #{repo}:#{tag}"
    rescue Docker::Error::NotFoundError
      "Image #{id} not found"
    rescue StandardError => e
      "Error tagging image: #{e.message}"
    end
  end

  TagImage = TAG_IMAGE_DEFINITION.to_mcp_tool
end
