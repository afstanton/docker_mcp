# frozen_string_literal: true

module DockerMCP
  class RemoveVolume < MCP::Tool
    description 'Remove a Docker volume'

    input_schema(
      properties: {
        name: {
          type: 'string',
          description: 'Volume name'
        },
        force: {
          type: 'boolean',
          description: 'Force removal of the volume (default: false)'
        }
      },
      required: ['name']
    )

    def self.call(name:, server_context:, force: false)
      volume = Docker::Volume.get(name)
      volume.remove(force: force)

      MCP::Tool::Response.new([{
                                type: 'text',
                                text: "Volume #{name} removed successfully"
                              }])
    rescue Docker::Error::NotFoundError
      MCP::Tool::Response.new([{
                                type: 'text',
                                text: "Volume #{name} not found"
                              }])
    rescue StandardError => e
      MCP::Tool::Response.new([{
                                type: 'text',
                                text: "Error removing volume: #{e.message}"
                              }])
    end
  end
end
