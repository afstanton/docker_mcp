# frozen_string_literal: true

module DockerMCP
  # MCP tool for recreating Docker containers.
  #
  # This tool provides a complete container recreation process that stops
  # the existing container, removes it, and creates a new container with
  # the same configuration. This is useful for applying image updates,
  # clearing container state, or resolving container corruption issues.
  #
  # == Features
  #
  # - Complete container recreation with preserved configuration
  # - Automatic stop, remove, and recreate sequence
  # - Preserves original container configuration and settings
  # - Configurable stop timeout for graceful shutdown
  # - Handles both running and stopped containers
  # - Maintains container networking and volume configurations
  #
  # == Security Considerations
  #
  # Container recreation involves several security considerations:
  # - **Service Downtime**: Temporary service interruption during recreation
  # - **Data Loss**: Container file system changes are lost (volumes preserved)
  # - **Resource Allocation**: New container may have different resource usage
  # - **Network Reconfiguration**: IP addresses may change
  # - **State Reset**: Application state within container is lost
  #
  # Plan recreations carefully and coordinate with dependent services.
  #
  # == Parameters
  #
  # - **id**: Container ID or name to recreate (required)
  # - **timeout**: Seconds to wait before killing container when stopping (optional, default: 10)
  #
  # == Process Flow
  #
  # 1. Inspect existing container to capture configuration
  # 2. Stop the running container (if running)
  # 3. Remove the stopped container
  # 4. Create new container with captured configuration
  # 5. Return new container information
  #
  # == Example Usage
  #
  #   # Recreate with default timeout
  #   response = RecreateContainer.call(
  #     server_context: context,
  #     id: "web-server"
  #   )
  #
  #   # Recreate with extended timeout
  #   response = RecreateContainer.call(
  #     server_context: context,
  #     id: "database",
  #     timeout: 30
  #   )
  #
  # @see Docker::Container#stop
  # @see Docker::Container#remove
  # @see Docker::Container.create
  # @since 0.1.0
  RECREATE_CONTAINER_DEFINITION = ToolForge.define(:recreate_container) do
    description 'Recreate a Docker container (stops, removes, and recreates with same configuration)'

    param :id,
          type: :string,
          description: 'Container ID or name to recreate'

    param :timeout,
          type: :integer,
          description: 'Seconds to wait before killing the container when stopping (default: 10)',
          required: false,
          default: 10

    execute do |id:, timeout: 10|
      # Get the existing container
      old_container = Docker::Container.get(id)
      config = old_container.json

      # Extract configuration we need to preserve
      image = config['Config']['Image']
      name = config['Name']&.delete_prefix('/')
      cmd = config['Config']['Cmd']
      env = config['Config']['Env']
      exposed_ports = config['Config']['ExposedPorts']
      host_config = config['HostConfig']

      # Stop and remove the old container
      old_container.stop('timeout' => timeout) if config['State']['Running']
      old_container.delete

      # Create new container with same config
      new_config = {
        'Image' => image,
        'Cmd' => cmd,
        'Env' => env,
        'ExposedPorts' => exposed_ports,
        'HostConfig' => host_config
      }
      new_config['name'] = name if name

      new_container = Docker::Container.create(new_config)

      # Start if the old one was running
      new_container.start if config['State']['Running']

      "Container #{id} recreated successfully. New ID: #{new_container.id}"
    rescue Docker::Error::NotFoundError
      "Container #{id} not found"
    rescue StandardError => e
      "Error recreating container: #{e.message}"
    end
  end

  RecreateContainer = RECREATE_CONTAINER_DEFINITION.to_mcp_tool
end
