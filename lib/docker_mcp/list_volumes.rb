# frozen_string_literal: true

module DockerMCP
  LIST_VOLUMES_DEFINITION = ToolForge.define(:list_volumes) do
    description 'List Docker volumes'

    execute do
      Docker::Volume.all.map(&:info)
    end
  end

  ListVolumes = LIST_VOLUMES_DEFINITION.to_mcp_tool
end
