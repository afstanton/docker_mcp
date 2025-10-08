# frozen_string_literal: true

module DockerMCP
  # MCP tool for stopping Docker containers.
  #
  # This tool gracefully stops a running Docker container by sending a
  # SIGTERM signal to the main process, allowing it to shut down cleanly.
  # If the container doesn't stop within the specified timeout, it will
  # be forcefully killed with SIGKILL.
  #
  # == Features
  #
  # - Graceful container shutdown with SIGTERM
  # - Configurable timeout for forced termination
  # - Supports container identification by ID or name
  # - Handles both running and already-stopped containers
  # - Provides clear feedback on operation status
  # - Preserves container and data integrity
  #
  # == Security Considerations
  #
  # Stopping containers affects service availability:
  # - **Service Disruption**: Terminates running services and processes
  # - **Data Integrity**: May interrupt ongoing operations
  # - **Resource Release**: Frees CPU, memory, and network resources
  # - **State Preservation**: Maintains container state for future restart
  #
  # Coordinate container stops with dependent services and users.
  #
  # == Parameters
  #
  # - **id**: Container ID or name (required)
  #   - Accepts full container IDs
  #   - Accepts short container IDs (first 12+ characters)
  #   - Accepts custom container names
  # - **timeout**: Seconds to wait before killing container (optional, default: 10)
  #
  # == Example Usage
  #
  #   # Stop with default timeout
  #   response = StopContainer.call(
  #     server_context: context,
  #     id: "web-server"
  #   )
  #
  #   # Stop with custom timeout
  #   response = StopContainer.call(
  #     server_context: context,
  #     id: "database",
  #     timeout: 30
  #   )
  #
  # @see Docker::Container#stop
  # @since 0.1.0
  STOP_CONTAINER_DEFINITION = ToolForge.define(:stop_container) do
    description 'Stop a Docker container'

    param :id,
          type: :string,
          description: 'Container ID or name'

    param :timeout,
          type: :integer,
          description: 'Seconds to wait before killing the container (default: 10)',
          required: false,
          default: 10

    execute do |id:, timeout: 10|
      container = Docker::Container.get(id)
      container.stop('timeout' => timeout)

      "Container #{id} stopped successfully"
    rescue Docker::Error::NotFoundError
      "Container #{id} not found"
    rescue StandardError => e
      "Error stopping container: #{e.message}"
    end
  end

  StopContainer = STOP_CONTAINER_DEFINITION.to_mcp_tool
end
