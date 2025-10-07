# frozen_string_literal: true

module DockerMCP
  # MCP tool for creating Docker networks.
  #
  # This tool provides the ability to create custom Docker networks for
  # container communication and isolation. Networks enable containers to
  # communicate securely while providing isolation from other network
  # segments.
  #
  # == Features
  #
  # - Create custom Docker networks
  # - Support for different network drivers
  # - Duplicate name detection
  # - Comprehensive error handling
  # - Flexible network configuration
  #
  # == Network Drivers
  #
  # Docker supports various network drivers:
  # - **bridge**: Default isolated network for single-host networking
  # - **host**: Remove network isolation, use host networking directly
  # - **overlay**: Multi-host networking for swarm services
  # - **macvlan**: Assign MAC addresses to containers
  # - **none**: Disable networking completely
  # - **Custom**: Third-party network drivers
  #
  # == Security Considerations
  #
  # Network creation affects system security:
  # - **Network Isolation**: Networks provide security boundaries
  # - **Traffic Control**: Custom networks enable traffic filtering
  # - **Access Control**: Networks control container communication
  # - **DNS Resolution**: Networks provide internal DNS services
  #
  # Security implications:
  # - Bridge networks isolate containers from host network
  # - Host networks expose containers to all host traffic
  # - Custom networks should follow least-privilege principles
  # - Network names may reveal infrastructure details
  #
  # Best practices:
  # - Use descriptive but not sensitive network names
  # - Implement network segmentation strategies
  # - Limit container access to necessary networks only
  # - Monitor network traffic and connections
  # - Regular audit of network configurations
  #
  # == Example Usage
  #
  #   # Create basic bridge network
  #   CreateNetwork.call(
  #     server_context: context,
  #     name: "app-network"
  #   )
  #
  #   # Create network with specific driver
  #   CreateNetwork.call(
  #     server_context: context,
  #     name: "frontend-net",
  #     driver: "bridge"
  #   )
  #
  #   # Create without duplicate checking
  #   CreateNetwork.call(
  #     server_context: context,
  #     name: "temp-network",
  #     check_duplicate: false
  #   )
  #
  # @see ListNetworks
  # @see RemoveNetwork
  # @see Docker::Network.create
  # @since 0.1.0
  class CreateNetwork < MCP::Tool
    description 'Create a Docker network'

    input_schema(
      properties: {
        name: {
          type: 'string',
          description: 'Name of the network'
        },
        driver: {
          type: 'string',
          description: 'Driver to use (default: bridge)'
        },
        check_duplicate: {
          type: 'boolean',
          description: 'Check for networks with duplicate names (default: true)'
        }
      },
      required: ['name']
    )

    # Create a new Docker network.
    #
    # This method creates a custom Docker network with the specified name
    # and driver. The network can then be used by containers for isolated
    # communication.
    #
    # @param name [String] name for the new network
    # @param server_context [Object] MCP server context (unused but required)
    # @param driver [String] network driver to use (default: "bridge")
    # @param check_duplicate [Boolean] whether to check for duplicate names (default: true)
    #
    # @return [MCP::Tool::Response] network creation results with network ID
    #
    # @raise [Docker::Error::ConflictError] if network name already exists
    # @raise [StandardError] for other network creation failures
    #
    # @example Create application network
    #   response = CreateNetwork.call(
    #     server_context: context,
    #     name: "webapp-network"
    #   )
    #
    # @example Create host network
    #   response = CreateNetwork.call(
    #     server_context: context,
    #     name: "high-performance-net",
    #     driver: "host"
    #   )
    #
    # @see Docker::Network.create
    def self.call(name:, server_context:, driver: 'bridge', check_duplicate: true)
      options = {
        'Name' => name,
        'Driver' => driver,
        'CheckDuplicate' => check_duplicate
      }

      network = Docker::Network.create(name, options)

      MCP::Tool::Response.new([{
                                type: 'text',
                                text: "Network #{name} created successfully. ID: #{network.id}"
                              }])
    rescue Docker::Error::ConflictError
      MCP::Tool::Response.new([{
                                type: 'text',
                                text: "Network #{name} already exists"
                              }])
    rescue StandardError => e
      MCP::Tool::Response.new([{
                                type: 'text',
                                text: "Error creating network: #{e.message}"
                              }])
    end
  end
end
