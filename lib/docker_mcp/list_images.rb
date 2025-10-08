# frozen_string_literal: true

module DockerMCP
  LIST_IMAGES_DEFINITION = ToolForge.define(:list_images) do
    description 'List Docker images'

    execute do
      Docker::Image.all.map(&:info)
    end
  end

  ListImages = LIST_IMAGES_DEFINITION.to_mcp_tool
end
