# frozen_string_literal: true

module DockerMCP
  # MCP tool for starting Docker containers.
  #
  # This tool starts a previously created Docker container that is currently
  # in a "created" or "stopped" state. It transitions the container to a
  # "running" state and begins executing the configured command or entrypoint.
  #
  # == Features
  #
  # - Starts containers by ID or name
  # - Supports both short and full container IDs
  # - Works with custom container names
  # - Provides clear success/failure feedback
  # - Handles container state transitions
  # - Preserves all container configuration
  #
  # == Security Considerations
  #
  # Starting containers involves security implications:
  # - **Process Execution**: Begins running container processes
  # - **Resource Activation**: Activates CPU, memory, and I/O usage
  # - **Network Activation**: Brings network interfaces online
  # - **Service Exposure**: Makes configured services accessible
  #
  # Ensure proper monitoring and access controls are in place.
  #
  # == Parameters
  #
  # - **id**: Container ID or name (required)
  #   - Accepts full container IDs
  #   - Accepts short container IDs (first 12+ characters)
  #   - Accepts custom container names
  #
  # == Example Usage
  #
  #   # Start by container name
  #   response = StartContainer.call(
  #     server_context: context,
  #     id: "web-server"
  #   )
  #
  #   # Start by container ID
  #   response = StartContainer.call(
  #     server_context: context,
  #     id: "a1b2c3d4e5f6"
  #   )
  #
  # @see Docker::Container#start
  # @since 0.1.0
  START_CONTAINER_DEFINITION = ToolForge.define(:start_container) do
    description 'Start a Docker container'

    param :id,
          type: :string,
          description: 'Container ID or name'

    execute do |id:|
      container = Docker::Container.get(id)
      container.start

      "Container #{id} started successfully"
    rescue Docker::Error::NotFoundError
      "Container #{id} not found"
    rescue StandardError => e
      "Error starting container: #{e.message}"
    end
  end

  StartContainer = START_CONTAINER_DEFINITION.to_mcp_tool
end
