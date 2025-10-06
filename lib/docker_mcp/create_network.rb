# frozen_string_literal: true

module DockerMCP
  class CreateNetwork < MCP::Tool
    description 'Create a Docker network'

    input_schema(
      properties: {
        name: {
          type: 'string',
          description: 'Name of the network'
        },
        driver: {
          type: 'string',
          description: 'Driver to use (default: bridge)'
        },
        check_duplicate: {
          type: 'boolean',
          description: 'Check for networks with duplicate names (default: true)'
        }
      },
      required: ['name']
    )

    def self.call(name:, server_context:, driver: 'bridge', check_duplicate: true)
      options = {
        'Name' => name,
        'Driver' => driver,
        'CheckDuplicate' => check_duplicate
      }

      network = Docker::Network.create(name, options)

      MCP::Tool::Response.new([{
                                type: 'text',
                                text: "Network #{name} created successfully. ID: #{network.id}"
                              }])
    rescue Docker::Error::ConflictError
      MCP::Tool::Response.new([{
                                type: 'text',
                                text: "Network #{name} already exists"
                              }])
    rescue StandardError => e
      MCP::Tool::Response.new([{
                                type: 'text',
                                text: "Error creating network: #{e.message}"
                              }])
    end
  end
end
