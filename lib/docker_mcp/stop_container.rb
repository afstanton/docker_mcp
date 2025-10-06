# frozen_string_literal: true

module DockerMCP
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
