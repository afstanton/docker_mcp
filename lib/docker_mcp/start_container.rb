# frozen_string_literal: true

module DockerMCP
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
