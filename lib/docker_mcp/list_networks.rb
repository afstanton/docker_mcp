# frozen_string_literal: true

module DockerMCP
  # MCP tool for listing Docker networks.
  #
  # This tool provides functionality to list all Docker networks available on
  # the system, including built-in networks (bridge, host, none) and custom
  # user-defined networks. It returns comprehensive information about network
  # configuration, drivers, and connected containers.
  #
  # == Features
  #
  # - List all Docker networks on the system
  # - Comprehensive network metadata
  # - No configuration required
  # - Read-only operation
  # - Includes built-in and custom networks
  #
  # == Network Information Included
  #
  # The response typically includes:
  # - **Network ID**: Unique identifier for the network
  # - **Name**: Human-readable network name
  # - **Driver**: Network driver (bridge, host, overlay, etc.)
  # - **Scope**: Network scope (local, global, swarm)
  # - **IPAM**: IP Address Management configuration
  # - **Connected Containers**: Containers attached to the network
  # - **Options**: Driver-specific configuration options
  #
  # == Security Considerations
  #
  # This is a read-only operation that reveals network topology:
  # - Exposes network architecture and segmentation
  # - Shows container connectivity patterns
  # - May reveal internal network design
  # - Could aid in network reconnaissance
  #
  # While generally safe, consider access control:
  # - Limit exposure of network topology information
  # - Be cautious with sensitive network names
  # - Monitor for unauthorized network discovery
  # - Consider network isolation requirements
  #
  # == Example Usage
  #
  #   # List all networks
  #   ListNetworks.call(server_context: context)
  #
  # @example Usage in network management
  #   # Get available networks before container creation
  #   networks_response = ListNetworks.call(server_context: context)
  #   # Use network information to select appropriate networks
  #
  # @see CreateNetwork
  # @see RemoveNetwork
  # @see Docker::Network.all
  # @since 0.1.0
  class ListNetworks < MCP::Tool
    description 'List Docker networks'

    # List all Docker networks available on the system.
    #
    # This method retrieves information about all Docker networks, including
    # both system-created networks (bridge, host, none) and user-defined
    # custom networks. The information includes comprehensive metadata for
    # each network.
    #
    # @param args [Array] variable arguments (unused but accepted for compatibility)
    #
    # @return [MCP::Tool::Response] comprehensive network information
    #
    # @example List all networks
    #   response = ListNetworks.call
    #   # Returns detailed info for all Docker networks
    #
    # @see Docker::Network.all
    def self.call(*)
      MCP::Tool::Response.new([{
                                type: 'text',
                                text: Docker::Network.all.map(&:info).to_s
                              }])
    end
  end
end
