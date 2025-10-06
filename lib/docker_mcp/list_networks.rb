# frozen_string_literal: true

module DockerMCP
  class ListNetworks < MCP::Tool
    description 'List Docker networks'

    def self.call(*)
      MCP::Tool::Response.new([{
                                type: 'text',
                                text: Docker::Network.all.map(&:info).to_s
                              }])
    end
  end
end
