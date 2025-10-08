# frozen_string_literal: true

require 'tool_forge'

module DockerMCP
  CREATE_CONTAINER_DEFINITION = ToolForge.define(:create_container) do
    description 'Create a Docker container'

    param :image,
          type: :string,
          description: 'Image name to use (e.g., "ubuntu:22.04")'

    param :name,
          type: :string,
          description: 'Container name (optional)',
          required: false

    param :cmd,
          type: :string,
          description: 'Command to run as space-separated string (optional, e.g., "npm start" or "python app.py")',
          required: false

    param :env,
          type: :string,
          description: 'Environment variables as comma-separated KEY=VALUE pairs (optional)',
          required: false

    param :exposed_ports,
          type: :object,
          description: 'Exposed ports as {"port/protocol": {}} (optional)',
          required: false

    param :host_config,
          type: :object,
          description: 'Host configuration including port bindings, volumes, etc. (optional)',
          required: false

    execute do |image:, name: nil, cmd: nil, env: nil, exposed_ports: nil, host_config: nil|
      config = { 'Image' => image }
      config['name'] = name if name

      # Parse cmd string into array if provided
      config['Cmd'] = Shellwords.split(cmd) if cmd && !cmd.strip.empty?

      # Parse env string into array if provided
      config['Env'] = env.split(',').map(&:strip) if env && !env.strip.empty?

      config['ExposedPorts'] = exposed_ports if exposed_ports
      config['HostConfig'] = host_config if host_config

      container = Docker::Container.create(config)
      container_name = container.info['Names']&.first&.delete_prefix('/')

      "Container created successfully. ID: #{container.id}, Name: #{container_name}"
    rescue Docker::Error::NotFoundError
      "Image #{image} not found"
    rescue Docker::Error::ConflictError
      "Container with name #{name} already exists"
    rescue StandardError => e
      "Error creating container: #{e.message}"
    end
  end

  CreateContainer = CREATE_CONTAINER_DEFINITION.to_mcp_tool
end
