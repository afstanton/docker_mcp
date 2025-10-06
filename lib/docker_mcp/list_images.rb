# frozen_string_literal: true

module DockerMcp
  class ListImages < MCP::Tool
    description 'List Docker images'

    def self.call(*)
      MCP::Tool::Response.new([{
                                type: 'text',
                                text: Docker::Image.all.map(&:info).to_s
                              }])
    end
  end
end
