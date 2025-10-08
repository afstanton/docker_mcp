# frozen_string_literal: true

module DockerMCP
  # MCP tool for removing Docker containers.
  #
  # This tool permanently removes a Docker container from the system,
  # including its file system, configuration, and metadata. This is a
  # destructive operation that cannot be undone. The container must
  # be stopped before removal unless force is specified.
  #
  # == Features
  #
  # - Permanent container removal from system
  # - Supports forced removal of running containers
  # - Optional removal of associated volumes
  # - Handles container identification by ID or name
  # - Provides comprehensive error handling
  # - Frees all associated system resources
  #
  # == Security Considerations
  #
  # Container removal is a destructive operation with implications:
  # - **Data Loss**: Permanently destroys container file system
  # - **Configuration Loss**: Removes container settings and metadata
  # - **Service Disruption**: Eliminates containerized services
  # - **Resource Recovery**: Frees storage, memory, and system resources
  # - **Audit Trail**: May remove forensic evidence if needed
  #
  # Implement proper backup and approval workflows for production systems.
  #
  # == Parameters
  #
  # - **id**: Container ID or name (required)
  #   - Accepts full container IDs
  #   - Accepts short container IDs (first 12+ characters)
  #   - Accepts custom container names
  # - **force**: Force removal of running container (optional, default: false)
  # - **volumes**: Remove associated volumes (optional, default: false)
  #
  # == Example Usage
  #
  #   # Remove stopped container
  #   response = RemoveContainer.call(
  #     server_context: context,
  #     id: "old-web-server"
  #   )
  #
  #   # Force remove running container with volumes
  #   response = RemoveContainer.call(
  #     server_context: context,
  #     id: "problematic-container",
  #     force: true,
  #     volumes: true
  #   )
  #
  # @see Docker::Container#remove
  # @since 0.1.0
  REMOVE_CONTAINER_DEFINITION = ToolForge.define(:remove_container) do
    description 'Remove a Docker container'

    param :id,
          type: :string,
          description: 'Container ID or name'

    param :force,
          type: :boolean,
          description: 'Force removal of running container (default: false)',
          required: false,
          default: false

    param :volumes,
          type: :boolean,
          description: 'Remove associated volumes (default: false)',
          required: false,
          default: false

    execute do |id:, force: false, volumes: false|
      container = Docker::Container.get(id)
      container.delete(force: force, v: volumes)

      "Container #{id} removed successfully"
    rescue Docker::Error::NotFoundError
      "Container #{id} not found"
    rescue StandardError => e
      "Error removing container: #{e.message}"
    end
  end

  RemoveContainer = REMOVE_CONTAINER_DEFINITION.to_mcp_tool
end
