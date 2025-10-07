# frozen_string_literal: true

module DockerMCP
  class Server
    attr_reader :server

    def initialize
      @server = MCP::Server.new(
        name: 'docker_mcp',
        tools: [
          BuildImage,
          CopyToContainer,
          CreateContainer,
          CreateNetwork,
          CreateVolume,
          ExecContainer,
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
          StopContainer,
          TagImage
        ]
      )
    end
  end
end
