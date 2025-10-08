# frozen_string_literal: true

module DockerMCP
  REMOVE_CONTAINER_DEFINITION = ToolForge.define(:remove_container) do
    description 'Remove a Docker container'

    param :id,
          type: :string,
          description: 'Container ID or name'

    param :force,
          type: :boolean,
          description: 'Force removal of running container (default: false)',
          required: false,
          default: false

    param :volumes,
          type: :boolean,
          description: 'Remove associated volumes (default: false)',
          required: false,
          default: false

    execute do |id:, force: false, volumes: false|
      container = Docker::Container.get(id)
      container.delete(force: force, v: volumes)

      "Container #{id} removed successfully"
    rescue Docker::Error::NotFoundError
      "Container #{id} not found"
    rescue StandardError => e
      "Error removing container: #{e.message}"
    end
  end

  RemoveContainer = REMOVE_CONTAINER_DEFINITION.to_mcp_tool
end
