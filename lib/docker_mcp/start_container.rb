# frozen_string_literal: true

module DockerMCP
  # MCP tool for starting existing Docker containers.
  #
  # This tool provides the ability to start Docker containers that have been
  # created but are currently stopped. It's the counterpart to StopContainer
  # and is commonly used after CreateContainer or when restarting stopped
  # containers.
  #
  # == Features
  #
  # - Start stopped containers by ID or name
  # - Simple and reliable container lifecycle management
  # - Comprehensive error handling
  # - Works with containers in any stopped state
  #
  # == Security Considerations
  #
  # Starting containers can have security implications:
  # - Containers resume with their original configuration
  # - Services become accessible on mapped ports
  # - Processes resume execution with previous privileges
  # - Network connections are re-established
  #
  # Ensure containers are properly configured before starting:
  # - Review port mappings and network exposure
  # - Verify volume mounts and file permissions
  # - Check environment variables for sensitive data
  # - Validate container image integrity
  #
  # == Example Usage
  #
  #   # Start container by name
  #   StartContainer.call(
  #     server_context: context,
  #     id: "web-server"
  #   )
  #
  #   # Start container by ID
  #   StartContainer.call(
  #     server_context: context,
  #     id: "a1b2c3d4e5f6"
  #   )
  #
  # @see CreateContainer
  # @see StopContainer
  # @see RunContainer
  # @see Docker::Container#start
  # @since 0.1.0
  class StartContainer < MCP::Tool
    description 'Start a Docker container'

    input_schema(
      properties: {
        id: {
          type: 'string',
          description: 'Container ID or name'
        }
      },
      required: ['id']
    )

    # Start an existing Docker container.
    #
    # This method starts a container that is currently in a stopped state.
    # The container must already exist and be in a startable state. If the
    # container is already running, Docker will typically ignore the start
    # command without error.
    #
    # @param id [String] container ID (full or short) or container name
    # @param server_context [Object] MCP server context (unused but required)
    #
    # @return [MCP::Tool::Response] start operation results
    #
    # @raise [Docker::Error::NotFoundError] if container doesn't exist
    # @raise [StandardError] for other start failures
    #
    # @example Start by container name
    #   response = StartContainer.call(
    #     server_context: context,
    #     id: "my-app-container"
    #   )
    #
    # @example Start by container ID
    #   response = StartContainer.call(
    #     server_context: context,
    #     id: "abc123def456"
    #   )
    #
    # @see Docker::Container#start
    def self.call(id:, server_context:)
      container = Docker::Container.get(id)
      container.start

      MCP::Tool::Response.new([{
                                type: 'text',
                                text: "Container #{id} started successfully"
                              }])
    rescue Docker::Error::NotFoundError
      MCP::Tool::Response.new([{
                                type: 'text',
                                text: "Container #{id} not found"
                              }])
    rescue StandardError => e
      MCP::Tool::Response.new([{
                                type: 'text',
                                text: "Error starting container: #{e.message}"
                              }])
    end
  end
end
