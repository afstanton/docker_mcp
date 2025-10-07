# frozen_string_literal: true

module DockerMCP
  # MCP tool for listing Docker containers.
  #
  # This tool provides functionality to list all Docker containers on the system,
  # including both running and stopped containers. It returns detailed information
  # about each container including names, images, status, ports, and other metadata.
  #
  # == Security Notes
  #
  # This is a read-only operation that provides system information about containers.
  # While generally safe, it may reveal information about the Docker environment
  # that could be useful for reconnaissance.
  #
  # == Example Usage
  #
  #   # List all containers (default behavior)
  #   ListContainers.call(server_context: context)
  #
  #   # Explicitly request all containers
  #   ListContainers.call(server_context: context, all: true)
  #
  # @see Docker::Container.all
  # @since 0.1.0
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

    # List all Docker containers with detailed information.
    #
    # Retrieves information about all containers on the system, including:
    # - Container names and IDs
    # - Image information
    # - Current state (running, stopped, etc.)
    # - Port mappings
    # - Network configuration
    # - Volume mounts
    # - Creation and status timestamps
    #
    # @param server_context [Object] the MCP server context (unused but required)
    # @param all [Boolean] whether to show all containers (default: true)
    # @return [MCP::Tool::Response] response containing container information
    #
    # @example List all containers
    #   response = ListContainers.call(server_context: context)
    #   # Returns detailed info for all containers
    #
    # @see Docker::Container.all
    def self.call(server_context:, all: true)
      MCP::Tool::Response.new([{
                                type: 'text',
                                text: Docker::Container.all(all: all).map(&:info).to_s
                              }])
    end
  end
end
