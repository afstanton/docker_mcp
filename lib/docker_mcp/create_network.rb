# frozen_string_literal: true

module DockerMCP
  # MCP tool for creating Docker networks.
  #
  # This tool provides the ability to create custom Docker networks
  # for container communication and isolation. Networks enable secure
  # and controlled communication between containers and external systems.
  #
  # == Features
  #
  # - Create custom Docker networks
  # - Support for multiple network drivers (bridge, overlay, host, etc.)
  # - Duplicate name checking and validation
  # - Network configuration and options
  # - Comprehensive error handling
  # - Network isolation and security controls
  #
  # == Security Considerations
  #
  # Network creation involves important security considerations:
  # - **Network Isolation**: Improper networks can compromise container isolation
  # - **Traffic Control**: Networks affect inter-container communication
  # - **External Access**: Bridge networks may expose containers externally
  # - **Resource Usage**: Networks consume system resources
  # - **DNS Resolution**: Custom networks affect service discovery
  # - **Firewall Bypass**: Networks can bypass host firewall rules
  #
  # **Security Recommendations**:
  # - Use appropriate network drivers for use case
  # - Implement network segmentation strategies
  # - Monitor network traffic and usage
  # - Avoid exposing internal networks externally
  # - Use network policies for access control
  # - Regular audit of network configurations
  #
  # == Parameters
  #
  # - **name**: Name of the network (required)
  # - **driver**: Driver to use (optional, default: "bridge")
  # - **check_duplicate**: Check for networks with duplicate names (optional, default: true)
  #
  # == Network Drivers
  #
  # - **bridge**: Default driver for single-host networking
  # - **overlay**: Multi-host networking for Docker Swarm
  # - **host**: Uses host's network stack directly
  # - **none**: Disables networking for containers
  # - **macvlan**: Assigns MAC addresses to containers
  #
  # == Example Usage
  #
  #   # Create basic bridge network
  #   response = CreateNetwork.call(
  #     server_context: context,
  #     name: "app-network"
  #   )
  #
  #   # Create overlay network for swarm
  #   response = CreateNetwork.call(
  #     server_context: context,
  #     name: "swarm-network",
  #     driver: "overlay"
  #   )
  #
  #   # Create network allowing duplicates
  #   response = CreateNetwork.call(
  #     server_context: context,
  #     name: "test-network",
  #     driver: "bridge",
  #     check_duplicate: false
  #   )
  #
  # @see Docker::Network.create
  # @since 0.1.0
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
