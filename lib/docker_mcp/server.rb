# frozen_string_literal: true

module DockerMCP
  class Server
    attr_reader :server

    def initialize
      @server = MCP::Server.new(
        name: 'docker_mcp',
        tools: [
          BuildImage,
          CreateContainer,
          CreateNetwork,
          CreateVolume,
          FetchContainerLogs,
          ListContainers,
          ListImages,
          ListNetworks,
          ListVolumes,
          PullImage,
          PushImage,
          RecreateContainer,
          RemoveContainer,
          RemoveImage,
          RemoveNetwork,
          RemoveVolume,
          RunContainer,
          StartContainer,
          StopContainer
        ]
      )
    end
  end
end
