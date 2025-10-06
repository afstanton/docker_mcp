# frozen_string_literal: true

module DockerMCP
  class Server
    attr_reader :server

    def initialize
      @server = MCP::Server.new(
        name: 'docker_mcp',
        tools: [ListImages]
      )
    end
  end
end
