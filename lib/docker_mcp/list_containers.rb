# frozen_string_literal: true

module DockerMCP
  class ListContainers < MCP::Tool
    description 'List Docker containers'

    def self.call(*)
      MCP::Tool::Response.new([{
                                type: 'text',
                                text: Docker::Container.all(all: true).map(&:info).to_s
                              }])
    end
  end
end
