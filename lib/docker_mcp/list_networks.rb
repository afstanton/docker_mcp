# frozen_string_literal: true

module DockerMCP
  LIST_NETWORKS_DEFINITION = ToolForge.define(:list_networks) do
    description 'List Docker networks'

    execute do
      Docker::Network.all.map(&:info)
    end
  end

  ListNetworks = LIST_NETWORKS_DEFINITION.to_mcp_tool
end
