# frozen_string_literal: true

module DockerMCP
  STOP_CONTAINER_DEFINITION = ToolForge.define(:stop_container) do
    description 'Stop a Docker container'

    param :id,
          type: :string,
          description: 'Container ID or name'

    param :timeout,
          type: :integer,
          description: 'Seconds to wait before killing the container (default: 10)',
          required: false,
          default: 10

    execute do |id:, timeout: 10|
      container = Docker::Container.get(id)
      container.stop('timeout' => timeout)

      "Container #{id} stopped successfully"
    rescue Docker::Error::NotFoundError
      "Container #{id} not found"
    rescue StandardError => e
      "Error stopping container: #{e.message}"
    end
  end

  StopContainer = STOP_CONTAINER_DEFINITION.to_mcp_tool
end
