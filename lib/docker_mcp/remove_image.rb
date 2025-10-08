# frozen_string_literal: true

module DockerMCP
  REMOVE_IMAGE_DEFINITION = ToolForge.define(:remove_image) do
    description 'Remove a Docker image'

    param :id,
          type: :string,
          description: 'Image ID, name, or name:tag'

    param :force,
          type: :boolean,
          description: 'Force removal of the image (default: false)',
          required: false,
          default: false

    param :noprune,
          type: :boolean,
          description: 'Do not delete untagged parents (default: false)',
          required: false,
          default: false

    execute do |id:, force: false, noprune: false|
      image = Docker::Image.get(id)
      image.remove(force: force, noprune: noprune)

      "Image #{id} removed successfully"
    rescue Docker::Error::NotFoundError
      "Image #{id} not found"
    rescue StandardError => e
      "Error removing image: #{e.message}"
    end
  end

  RemoveImage = REMOVE_IMAGE_DEFINITION.to_mcp_tool
end
