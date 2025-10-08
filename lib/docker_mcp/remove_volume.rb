# frozen_string_literal: true

module DockerMCP
  REMOVE_VOLUME_DEFINITION = ToolForge.define(:remove_volume) do
    description 'Remove a Docker volume'

    param :name,
          type: :string,
          description: 'Volume name'

    param :force,
          type: :boolean,
          description: 'Force removal of the volume (default: false)',
          required: false,
          default: false

    execute do |name:, force: false|
      volume = Docker::Volume.get(name)
      volume.remove(force: force)

      "Volume #{name} removed successfully"
    rescue Docker::Error::NotFoundError
      "Volume #{name} not found"
    rescue StandardError => e
      "Error removing volume: #{e.message}"
    end
  end

  RemoveVolume = REMOVE_VOLUME_DEFINITION.to_mcp_tool
end
