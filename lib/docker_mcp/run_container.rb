# frozen_string_literal: true

module DockerMCP
  # MCP tool for running Docker containers.
  #
  # This tool creates and immediately starts a Docker container from a
  # specified image in a single operation. It combines the functionality
  # of create_container and start_container for convenience when immediate
  # execution is desired.
  #
  # == Features
  #
  # - Creates and starts containers in one operation
  # - Supports all container configuration options
  # - Configures command execution and environment variables
  # - Sets up port exposure and network configuration
  # - Applies advanced host configurations and volume mounts
  # - Handles container naming and labeling
  #
  # == Security Considerations
  #
  # Running containers involves significant security considerations:
  # - **Immediate Execution**: Starts processes immediately upon creation
  # - **Resource Consumption**: Consumes CPU, memory, and storage resources
  # - **Network Exposure**: Creates active network endpoints
  # - **File System Access**: Potentially accesses host directories
  # - **Process Isolation**: Runs processes with configured privileges
  #
  # Implement strict access controls and resource monitoring.
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
  #   # Simple container execution
  #   response = RunContainer.call(
  #     server_context: context,
  #     image: "alpine:latest",
  #     cmd: "echo 'Hello World'"
  #   )
  #
  #   # Web server with port binding
  #   response = RunContainer.call(
  #     server_context: context,
  #     image: "nginx:latest",
  #     name: "web-server",
  #     exposed_ports: {"80/tcp" => {}},
  #     host_config: {
  #       "PortBindings" => {"80/tcp" => [{"HostPort" => "8080"}]}
  #     }
  #   )
  #
  # @see Docker::Container.create
  # @since 0.1.0
  RUN_CONTAINER_DEFINITION = ToolForge.define(:run_container) do
    description 'Run a Docker container (create and start)'

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
      container.start
      container_name = container.info['Names']&.first&.delete_prefix('/')

      "Container started successfully. ID: #{container.id}, Name: #{container_name}"
    rescue Docker::Error::NotFoundError
      "Image #{image} not found"
    rescue Docker::Error::ConflictError
      "Container with name #{name} already exists"
    rescue StandardError => e
      "Error running container: #{e.message}"
    end
  end

  RunContainer = RUN_CONTAINER_DEFINITION.to_mcp_tool
end
