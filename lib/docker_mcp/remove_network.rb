# frozen_string_literal: true

module DockerMCP
  class RemoveNetwork < MCP::Tool
    description 'Remove a Docker network'

    input_schema(
      properties: {
        id: {
          type: 'string',
          description: 'Network ID or name'
        }
      },
      required: ['id']
    )

    def self.call(id:, server_context:)
      network = Docker::Network.get(id)
      network.delete

      MCP::Tool::Response.new([{
                                type: 'text',
                                text: "Network #{id} removed successfully"
                              }])
    rescue Docker::Error::NotFoundError
      MCP::Tool::Response.new([{
                                type: 'text',
                                text: "Network #{id} not found"
                              }])
    rescue StandardError => e
      MCP::Tool::Response.new([{
                                type: 'text',
                                text: "Error removing network: #{e.message}"
                              }])
    end
  end
end
