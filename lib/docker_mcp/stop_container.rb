# frozen_string_literal: true

module DockerMCP
  # MCP tool for stopping running Docker containers.
  #
  # This tool provides the ability to gracefully stop running Docker containers
  # with configurable timeout handling. It sends a SIGTERM signal to the main
  # process and waits for the specified timeout before forcibly killing the
  # container with SIGKILL.
  #
  # == Features
  #
  # - Graceful container shutdown with SIGTERM
  # - Configurable timeout before force kill
  # - Works with containers by ID or name
  # - Comprehensive error handling
  # - Safe for already stopped containers
  #
  # == Shutdown Process
  #
  # 1. Send SIGTERM to container's main process
  # 2. Wait for graceful shutdown up to timeout
  # 3. Send SIGKILL if container hasn't stopped
  # 4. Return success when container is stopped
  #
  # == Security Considerations
  #
  # Stopping containers affects service availability:
  # - Services become unavailable immediately
  # - Network connections are terminated
  # - Data may be lost if not properly persisted
  # - Dependent services may be affected
  #
  # Best practices:
  # - Ensure data persistence before stopping
  # - Consider impact on dependent services
  # - Use appropriate timeout for graceful shutdown
  # - Monitor application logs during shutdown
  #
  # == Example Usage
  #
  #   # Stop with default timeout (10 seconds)
  #   StopContainer.call(
  #     server_context: context,
  #     id: "web-server"
  #   )
  #
  #   # Stop with custom timeout
  #   StopContainer.call(
  #     server_context: context,
  #     id: "database",
  #     timeout: 30
  #   )
  #
  # @see StartContainer
  # @see RemoveContainer
  # @see Docker::Container#stop
  # @since 0.1.0
  class StopContainer < MCP::Tool
    description 'Stop a Docker container'

    input_schema(
      properties: {
        id: {
          type: 'string',
          description: 'Container ID or name'
        },
        timeout: {
          type: 'integer',
          description: 'Seconds to wait before killing the container (default: 10)'
        }
      },
      required: ['id']
    )

    # Stop a running Docker container gracefully.
    #
    # This method stops a container by sending SIGTERM to the main process
    # and waiting for the specified timeout before sending SIGKILL. The
    # operation is idempotent - stopping an already stopped container
    # typically succeeds without error.
    #
    # @param id [String] container ID (full or short) or container name
    # @param server_context [Object] MCP server context (unused but required)
    # @param timeout [Integer] seconds to wait before force killing (default: 10)
    #
    # @return [MCP::Tool::Response] stop operation results
    #
    # @raise [Docker::Error::NotFoundError] if container doesn't exist
    # @raise [StandardError] for other stop failures
    #
    # @example Stop with default timeout
    #   response = StopContainer.call(
    #     server_context: context,
    #     id: "nginx-server"
    #   )
    #
    # @example Stop database with longer timeout
    #   response = StopContainer.call(
    #     server_context: context,
    #     id: "postgres-db",
    #     timeout: 60  # Allow more time for DB shutdown
    #   )
    #
    # @see Docker::Container#stop
    def self.call(id:, server_context:, timeout: 10)
      container = Docker::Container.get(id)
      container.stop('timeout' => timeout)

      MCP::Tool::Response.new([{
                                type: 'text',
                                text: "Container #{id} stopped successfully"
                              }])
    rescue Docker::Error::NotFoundError
      MCP::Tool::Response.new([{
                                type: 'text',
                                text: "Container #{id} not found"
                              }])
    rescue StandardError => e
      MCP::Tool::Response.new([{
                                type: 'text',
                                text: "Error stopping container: #{e.message}"
                              }])
    end
  end
end
