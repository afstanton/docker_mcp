# frozen_string_literal: true

module DockerMCP
  # MCP tool for creating Docker containers.
  #
  # This tool creates a new Docker container from a specified image without
  # starting it. The container is created in a "created" state and can be
  # started later using the start_container tool. This two-step process
  # allows for container configuration before execution.
  #
  # == Features
  #
  # - Creates containers from any available Docker image
  # - Supports custom container naming
  # - Configures command execution and environment variables
  # - Sets up port exposure and network configuration
  # - Applies advanced host configurations
  # - Handles container labeling and metadata
  #
  # == Security Considerations
  #
  # Container creation is a powerful operation that can:
  # - **Resource Allocation**: Consume system resources and storage
  # - **Network Access**: Create network endpoints and bindings
  # - **File System Access**: Mount host directories and volumes
  # - **Security Context**: Run with elevated privileges if configured
  #
  # Implement proper access controls and resource limits.
  #
  # == Parameters
  #
  # - **image**: Docker image to use (required)
  # - **name**: Custom container name (optional)
  # - **cmd**: Command to execute as space-separated string (optional)
  # - **env**: Environment variables as comma-separated KEY=VALUE pairs (optional)
  # - **exposed_ports**: Port exposure configuration as JSON object (optional)
  # - **host_config**: Advanced host configuration as JSON object (optional)
  #
  # == Example Usage
  #
  #   # Simple container creation
  #   response = CreateContainer.call(
  #     server_context: context,
  #     image: "nginx:latest",
  #     name: "web-server"
  #   )
  #
  #   # Advanced container with configuration
  #   response = CreateContainer.call(
  #     server_context: context,
  #     image: "postgres:13",
  #     name: "database",
  #     env: "POSTGRES_PASSWORD=secret,POSTGRES_DB=myapp",
  #     exposed_ports: {"5432/tcp" => {}},
  #     host_config: {
  #       "PortBindings" => {"5432/tcp" => [{"HostPort" => "5432"}]},
  #       "Binds" => ["/host/data:/var/lib/postgresql/data:rw"]
  #     }
  #   )
  #
  # @see Docker::Container.create
  # @since 0.1.0
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
