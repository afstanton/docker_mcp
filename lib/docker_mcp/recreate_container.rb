# frozen_string_literal: true

module DockerMCP
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
