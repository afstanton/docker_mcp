# frozen_string_literal: true

module DockerMCP
  class RemoveContainer < MCP::Tool
    description 'Remove a Docker container'

    input_schema(
      properties: {
        id: {
          type: 'string',
          description: 'Container ID or name'
        },
        force: {
          type: 'boolean',
          description: 'Force removal of running container (default: false)'
        },
        volumes: {
          type: 'boolean',
          description: 'Remove associated volumes (default: false)'
        }
      },
      required: ['id']
    )

    def self.call(id:, server_context:, force: false, volumes: false)
      container = Docker::Container.get(id)
      container.delete(force: force, v: volumes)

      MCP::Tool::Response.new([{
                                type: 'text',
                                text: "Container #{id} removed successfully"
                              }])
    rescue Docker::Error::NotFoundError
      MCP::Tool::Response.new([{
                                type: 'text',
                                text: "Container #{id} not found"
                              }])
    rescue StandardError => e
      MCP::Tool::Response.new([{
                                type: 'text',
                                text: "Error removing container: #{e.message}"
                              }])
    end
  end
end
