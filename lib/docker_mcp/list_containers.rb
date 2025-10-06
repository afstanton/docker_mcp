# frozen_string_literal: true

module DockerMCP
  class ListContainers < MCP::Tool
    description 'List Docker containers'

    input_schema(
      properties: {
        all: {
          type: 'boolean',
          description: 'Show all containers (default shows all containers including stopped ones)'
        }
      },
      required: []
    )

    def self.call(server_context:, all: true)
      MCP::Tool::Response.new([{
                                type: 'text',
                                text: Docker::Container.all(all: all).map(&:info).to_s
                              }])
    end
  end
end
