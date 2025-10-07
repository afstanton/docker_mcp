# frozen_string_literal: true

module DockerMCP
  # MCP Server implementation for Docker management tools.
  #
  # The Server class initializes and configures a Model Context Protocol server
  # with all available Docker management tools. It serves as the main entry point
  # for Docker operations through the MCP interface.
  #
  # The server provides 22 comprehensive tools organized into four categories:
  # - Container Management: 10 tools for container lifecycle operations
  # - Image Management: 6 tools for Docker image operations
  # - Network Management: 3 tools for Docker network operations
  # - Volume Management: 3 tools for Docker volume operations
  #
  # == Security Considerations
  #
  # This server includes potentially dangerous tools that can:
  # - Execute arbitrary commands in containers (ExecContainer)
  # - Copy files between host and containers (CopyToContainer)
  # - Create, modify, and delete Docker resources
  #
  # Ensure proper security measures when exposing this server to external clients.
  #
  # == Example Usage
  #
  #   # Initialize the server
  #   server = DockerMCP::Server.new
  #
  #   # Access the underlying MCP server
  #   mcp_server = server.server
  #
  #   # The server automatically registers all available tools
  #
  # @see MCP::Server
  # @since 0.1.0
  class Server
    # The underlying MCP::Server instance.
    #
    # @return [MCP::Server] the configured MCP server with all Docker tools
    attr_reader :server

    # Initialize a new DockerMCP server with all available tools.
    #
    # Creates and configures an MCP::Server instance with all 22 Docker
    # management tools. The tools are automatically loaded and registered
    # with the server.
    #
    # Tools are registered in alphabetical order for consistency:
    # - BuildImage: Build Docker images from Dockerfiles
    # - CopyToContainer: Copy files/directories from host to container
    # - CreateContainer: Create new containers from images
    # - CreateNetwork: Create Docker networks
    # - CreateVolume: Create Docker volumes
    # - ExecContainer: Execute commands inside containers
    # - FetchContainerLogs: Retrieve container logs
    # - ListContainers: List all containers
    # - ListImages: List all images
    # - ListNetworks: List all networks
    # - ListVolumes: List all volumes
    # - PullImage: Pull images from registries
    # - PushImage: Push images to registries
    # - RecreateContainer: Recreate containers with same config
    # - RemoveContainer: Delete containers
    # - RemoveImage: Delete images
    # - RemoveNetwork: Delete networks
    # - RemoveVolume: Delete volumes
    # - RunContainer: Create and start containers
    # - StartContainer: Start existing containers
    # - StopContainer: Stop running containers
    # - TagImage: Tag images with new names
    #
    # @example Initialize server
    #   server = DockerMCP::Server.new
    #   puts server.server.tools.length # => 22
    #
    # @see MCP::Server#new
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
