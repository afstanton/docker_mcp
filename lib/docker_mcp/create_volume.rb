# frozen_string_literal: true

module DockerMCP
  CREATE_VOLUME_DEFINITION = ToolForge.define(:create_volume) do
    description 'Create a Docker volume'

    param :name,
          type: :string,
          description: 'Name of the volume'

    param :driver,
          type: :string,
          description: 'Driver to use (default: local)',
          required: false,
          default: 'local'

    execute do |name:, driver: 'local'|
      options = {
        'Name' => name,
        'Driver' => driver
      }

      Docker::Volume.create(name, options)

      "Volume #{name} created successfully"
    rescue Docker::Error::ConflictError
      "Volume #{name} already exists"
    rescue StandardError => e
      "Error creating volume: #{e.message}"
    end
  end

  CreateVolume = CREATE_VOLUME_DEFINITION.to_mcp_tool
end
