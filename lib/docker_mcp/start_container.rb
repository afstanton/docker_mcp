# frozen_string_literal: true

require 'tool_forge'

module DockerMCP
  START_CONTAINER_DEFINITION = ToolForge.define(:start_container) do
    description 'Start a Docker container'

    param :id,
          type: :string,
          description: 'Container ID or name'

    execute do |id:|
      container = Docker::Container.get(id)
      container.start

      "Container #{id} started successfully"
    rescue Docker::Error::NotFoundError
      "Container #{id} not found"
    rescue StandardError => e
      "Error starting container: #{e.message}"
    end
  end

  StartContainer = START_CONTAINER_DEFINITION.to_mcp_tool
end
