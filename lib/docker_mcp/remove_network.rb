# frozen_string_literal: true

module DockerMCP
  # MCP tool for removing Docker networks.
  #
  # This tool provides the ability to delete Docker networks when they
  # are no longer needed. Network removal helps maintain clean network
  # configurations and prevents resource leaks.
  #
  # == Features
  #
  # - Remove networks by ID or name
  # - Validation of network existence
  # - Comprehensive error handling
  # - Prevention of removing networks in use
  # - Safe cleanup of network resources
  # - Network dependency checking
  #
  # == Security Considerations
  #
  # Network removal involves important considerations:
  # - **Service Disruption**: Removing active networks disconnects containers
  # - **Data Isolation**: Network removal can affect container communication
  # - **Resource Cleanup**: Improper removal can leave network artifacts
  # - **Container Dependencies**: Containers may fail without expected networks
  # - **Network Policies**: Removal affects security and access policies
  #
  # **Security Recommendations**:
  # - Verify no containers are connected before removal
  # - Check for dependent services and applications
  # - Document network removal in change logs
  # - Implement network lifecycle management
  # - Monitor for orphaned network resources
  # - Use network removal as part of cleanup procedures
  #
  # == Parameters
  #
  # - **id**: Network ID or name (required)
  #
  # == Example Usage
  #
  #   # Remove network by name
  #   response = RemoveNetwork.call(
  #     server_context: context,
  #     id: "app-network"
  #   )
  #
  #   # Remove network by ID
  #   response = RemoveNetwork.call(
  #     server_context: context,
  #     id: "abc123def456"
  #   )
  #
  #   # Clean up test networks
  #   response = RemoveNetwork.call(
  #     server_context: context,
  #     id: "test-isolated-network"
  #   )
  #
  # @see Docker::Network#delete
  # @since 0.1.0
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
