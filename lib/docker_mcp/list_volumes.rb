# frozen_string_literal: true

module DockerMCP
  class ListVolumes < MCP::Tool
    description 'List Docker volumes'

    def self.call(*)
      MCP::Tool::Response.new([{
                                type: 'text',
                                text: Docker::Volume.all.map(&:info).to_s
                              }])
    end
  end
end
