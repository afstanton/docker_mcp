# frozen_string_literal: true

module DockerMCP
  class CreateVolume < MCP::Tool
    description 'Create a Docker volume'

    input_schema(
      properties: {
        name: {
          type: 'string',
          description: 'Name of the volume'
        },
        driver: {
          type: 'string',
          description: 'Driver to use (default: local)'
        }
      },
      required: ['name']
    )

    def self.call(name:, server_context:, driver: 'local')
      options = {
        'Name' => name,
        'Driver' => driver
      }

      Docker::Volume.create(name, options)

      MCP::Tool::Response.new([{
                                type: 'text',
                                text: "Volume #{name} created successfully"
                              }])
    rescue Docker::Error::ConflictError
      MCP::Tool::Response.new([{
                                type: 'text',
                                text: "Volume #{name} already exists"
                              }])
    rescue StandardError => e
      MCP::Tool::Response.new([{
                                type: 'text',
                                text: "Error creating volume: #{e.message}"
                              }])
    end
  end
end
