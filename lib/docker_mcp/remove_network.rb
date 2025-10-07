# frozen_string_literal: true

module DockerMCP
  # MCP tool for removing Docker networks.
  #
  # This tool provides the ability to permanently delete Docker networks from
  # the system. It safely removes custom networks while protecting built-in
  # system networks from accidental deletion.
  #
  # == Features
  #
  # - Remove custom Docker networks by ID or name
  # - Protection against removing built-in networks
  # - Comprehensive error handling
  # - Dependency checking (prevents removal if containers are connected)
  # - Safe cleanup of network resources
  #
  # == ⚠️ Service Disruption Warning ⚠️
  #
  # **NETWORK REMOVAL CAN DISRUPT SERVICES**
  #
  # Removing networks can cause immediate service disruption:
  # - Connected containers lose network connectivity
  # - Inter-container communication is broken
  # - Services may become unreachable
  # - Application functionality can be severely impacted
  # - Network-dependent processes may fail
  #
  # == Protected Networks
  #
  # Docker protects certain built-in networks from removal:
  # - **bridge**: Default bridge network
  # - **host**: Host networking
  # - **none**: No networking
  # - **System networks**: Docker-managed networks
  #
  # == Security Considerations
  #
  # Network removal affects security boundaries:
  # - Removes network isolation between containers
  # - May expose containers to unintended networks
  # - Could impact security segmentation strategies
  # - Affects network-based access controls
  #
  # Security implications:
  # - Ensure no critical containers depend on the network
  # - Verify alternative connectivity exists if needed
  # - Consider impact on security boundaries
  # - Monitor for unauthorized network modifications
  #
  # Best practices:
  # - Stop containers before removing their networks
  # - Verify network dependencies before removal
  # - Have rollback plans for critical networks
  # - Document network removal procedures
  # - Monitor network connectivity after removal
  #
  # == Example Usage
  #
  #   # Remove custom network
  #   RemoveNetwork.call(
  #     server_context: context,
  #     id: "app-network"
  #   )
  #
  #   # Remove by network ID
  #   RemoveNetwork.call(
  #     server_context: context,
  #     id: "abc123def456"
  #   )
  #
  # @see CreateNetwork
  # @see ListNetworks
  # @see Docker::Network#delete
  # @since 0.1.0
  class RemoveNetwork < MCP::Tool
    description 'Remove a Docker network'

    input_schema(
      properties: {
        id: {
          type: 'string',
          description: 'Network ID or name'
        }
      },
      required: ['id']
    )

    # Remove a Docker network from the system.
    #
    # This method permanently deletes the specified network. The network
    # must not have any containers connected to it, and built-in system
    # networks cannot be removed.
    #
    # @param id [String] network ID or name to remove
    # @param server_context [Object] MCP server context (unused but required)
    #
    # @return [MCP::Tool::Response] removal operation results
    #
    # @raise [Docker::Error::NotFoundError] if network doesn't exist
    # @raise [StandardError] for removal failures or dependency conflicts
    #
    # @example Remove custom network
    #   response = RemoveNetwork.call(
    #     server_context: context,
    #     id: "frontend-network"
    #   )
    #
    # @example Remove by ID
    #   response = RemoveNetwork.call(
    #     server_context: context,
    #     id: "1a2b3c4d5e6f"
    #   )
    #
    # @see Docker::Network#delete
    def self.call(id:, server_context:)
      network = Docker::Network.get(id)
      network.delete

      MCP::Tool::Response.new([{
                                type: 'text',
                                text: "Network #{id} removed successfully"
                              }])
    rescue Docker::Error::NotFoundError
      MCP::Tool::Response.new([{
                                type: 'text',
                                text: "Network #{id} not found"
                              }])
    rescue StandardError => e
      MCP::Tool::Response.new([{
                                type: 'text',
                                text: "Error removing network: #{e.message}"
                              }])
    end
  end
end
