# frozen_string_literal: true

require 'tool_forge'

module DockerMCP
  CREATE_NETWORK_DEFINITION = ToolForge.define(:create_network) do
    description 'Create a Docker network'

    param :name,
          type: :string,
          description: 'Name of the network'

    param :driver,
          type: :string,
          description: 'Driver to use (default: bridge)',
          required: false,
          default: 'bridge'

    param :check_duplicate,
          type: :boolean,
          description: 'Check for networks with duplicate names (default: true)',
          required: false,
          default: true

    execute do |name:, driver: 'bridge', check_duplicate: true|
      options = {
        'Name' => name,
        'Driver' => driver,
        'CheckDuplicate' => check_duplicate
      }

      network = Docker::Network.create(name, options)

      "Network #{name} created successfully. ID: #{network.id}"
    rescue Docker::Error::ConflictError
      "Network #{name} already exists"
    rescue StandardError => e
      "Error creating network: #{e.message}"
    end
  end

  CreateNetwork = CREATE_NETWORK_DEFINITION.to_mcp_tool
end
