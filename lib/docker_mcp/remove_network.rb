# frozen_string_literal: true

require 'tool_forge'

module DockerMCP
  REMOVE_NETWORK_DEFINITION = ToolForge.define(:remove_network) do
    description 'Remove a Docker network'

    param :id,
          type: :string,
          description: 'Network ID or name'

    execute do |id:|
      network = Docker::Network.get(id)
      network.delete

      "Network #{id} removed successfully"
    rescue Docker::Error::NotFoundError
      "Network #{id} not found"
    rescue StandardError => e
      "Error removing network: #{e.message}"
    end
  end

  RemoveNetwork = REMOVE_NETWORK_DEFINITION.to_mcp_tool
end
