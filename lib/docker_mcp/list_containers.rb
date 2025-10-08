# frozen_string_literal: true

module DockerMCP
  # MCP tool for listing Docker containers.
  #
  # This tool provides comprehensive information about all Docker containers
  # on the system, including both running and stopped containers. It returns
  # detailed metadata for each container including names, images, status,
  # network configuration, and resource usage.
  #
  # == Features
  #
  # - Lists all containers (running and stopped)
  # - Provides detailed container metadata
  # - Shows network configuration and port mappings
  # - Displays resource usage and statistics
  # - Includes mount point information
  # - Shows container labels and annotations
  #
  # == Security Considerations
  #
  # This tool provides system information that could be useful for:
  # - **System Reconnaissance**: Reveals running services and configurations
  # - **Network Discovery**: Shows internal network topology
  # - **Resource Analysis**: Exposes system resource usage patterns
  #
  # Use with appropriate access controls in production environments.
  #
  # == Return Format
  #
  # Returns an array of container objects with comprehensive metadata:
  # - Container names and IDs
  # - Image information and tags
  # - Current state and status
  # - Network settings and port bindings
  # - Mount points and volumes
  # - Labels and environment details
  #
  # == Example Usage
  #
  #   containers = ListContainers.call(server_context: context)
  #   containers.each do |container|
  #     puts "#{container['Names'].first}: #{container['State']}"
  #   end
  #
  # @see Docker::Container.all
  # @since 0.1.0
  LIST_CONTAINERS_DEFINITION = ToolForge.define(:list_containers) do
    description 'List Docker containers'

    param :all,
          type: :boolean,
          description: 'Show all containers (default shows all containers including stopped ones)',
          required: false,
          default: true

    execute do |all: true|
      Docker::Container.all(all: all).map(&:info)
    end
  end

  ListContainers = LIST_CONTAINERS_DEFINITION.to_mcp_tool
end
