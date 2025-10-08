# frozen_string_literal: true

module DockerMCP
  # MCP tool for listing Docker networks.
  #
  # This tool provides comprehensive information about all Docker networks
  # configured on the system. It returns detailed network configuration
  # including IPAM settings, connected containers, and network drivers.
  #
  # == Features
  #
  # - Lists all Docker networks (built-in and custom)
  # - Provides detailed network configuration
  # - Shows IPAM (IP Address Management) settings
  # - Displays connected containers
  # - Includes driver information and options
  # - Reports network scope and capabilities
  #
  # == Security Considerations
  #
  # Network information can be sensitive as it reveals:
  # - **Network Topology**: Internal network architecture
  # - **IP Addressing**: Subnet configurations and ranges
  # - **Container Connectivity**: Service interconnections
  # - **Network Isolation**: Security boundary configurations
  #
  # Restrict access to this tool in production environments.
  #
  # == Return Format
  #
  # Returns an array of network objects with comprehensive metadata:
  # - Network names and IDs
  # - Driver types and configurations
  # - IPAM settings and subnet information
  # - Connected container details
  # - Network options and labels
  # - Scope and capability flags
  #
  # == Example Usage
  #
  #   networks = ListNetworks.call(server_context: context)
  #   networks.each do |network|
  #     puts "#{network['Name']}: #{network['Driver']}"
  #   end
  #
  # @see Docker::Network.all
  # @since 0.1.0
  LIST_NETWORKS_DEFINITION = ToolForge.define(:list_networks) do
    description 'List Docker networks'

    execute do
      Docker::Network.all.map(&:info)
    end
  end

  ListNetworks = LIST_NETWORKS_DEFINITION.to_mcp_tool
end
