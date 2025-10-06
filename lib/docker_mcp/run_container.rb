# frozen_string_literal: true

module DockerMCP
  class RunContainer < MCP::Tool
    description 'Run a Docker container (create and start)'

    input_schema(
      properties: {
        image: {
          type: 'string',
          description: 'Image name to use (e.g., "ubuntu:22.04")'
        },
        name: {
          type: 'string',
          description: 'Container name (optional)'
        },
        cmd: {
          type: 'array',
          items: { type: 'string' },
          description: 'Command to run (optional)'
        },
        env: {
          type: 'array',
          items: { type: 'string' },
          description: 'Environment variables as KEY=VALUE (optional)'
        },
        exposed_ports: {
          type: 'object',
          description: 'Exposed ports as {"port/protocol": {}} (optional)'
        },
        host_config: {
          type: 'object',
          description: 'Host configuration including port bindings, volumes, etc. (optional)'
        }
      },
      required: ['image']
    )

    def self.call(image:, server_context:, name: nil, cmd: nil, env: nil, exposed_ports: nil, host_config: nil)
      config = { 'Image' => image }
      config['name'] = name if name
      config['Cmd'] = cmd if cmd
      config['Env'] = env if env
      config['ExposedPorts'] = exposed_ports if exposed_ports
      config['HostConfig'] = host_config if host_config

      container = Docker::Container.create(config)
      container.start
      container_name = container.info['Names']&.first&.delete_prefix('/')

      MCP::Tool::Response.new([{
                                type: 'text',
                                text: "Container started successfully. ID: #{container.id}, Name: #{container_name}"
                              }])
    rescue Docker::Error::NotFoundError
      MCP::Tool::Response.new([{
                                type: 'text',
                                text: "Image #{image} not found"
                              }])
    rescue Docker::Error::ConflictError
      MCP::Tool::Response.new([{
                                type: 'text',
                                text: "Container with name #{name} already exists"
                              }])
    rescue StandardError => e
      MCP::Tool::Response.new([{
                                type: 'text',
                                text: "Error running container: #{e.message}"
                              }])
    end
  end
end
