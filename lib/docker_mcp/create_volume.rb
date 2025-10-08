# frozen_string_literal: true

module DockerMCP
  # MCP tool for creating Docker volumes.
  #
  # This tool provides the ability to create Docker volumes for persistent
  # data storage. Volumes are essential for maintaining data across container
  # lifecycles and enabling data sharing between containers.
  #
  # == Features
  #
  # - Create named Docker volumes
  # - Support for multiple volume drivers
  # - Persistent data storage management
  # - Volume driver configuration
  # - Comprehensive error handling
  # - Volume lifecycle management
  #
  # == Security Considerations
  #
  # Volume creation involves important security considerations:
  # - **Data Persistence**: Volumes store data beyond container lifecycle
  # - **Access Control**: Volume permissions affect data security
  # - **Data Isolation**: Improper volumes can compromise data separation
  # - **Storage Security**: Volume drivers may have security implications
  # - **Resource Usage**: Volumes consume disk space and system resources
  # - **Data Leakage**: Shared volumes can expose sensitive data
  #
  # **Security Recommendations**:
  # - Use appropriate volume drivers for security requirements
  # - Implement proper access controls and permissions
  # - Monitor volume usage and capacity
  # - Regular backup of critical volume data
  # - Audit volume access patterns
  # - Use encryption for sensitive data volumes
  # - Implement volume lifecycle policies
  #
  # == Parameters
  #
  # - **name**: Name of the volume (required)
  # - **driver**: Driver to use (optional, default: "local")
  #
  # == Volume Drivers
  #
  # - **local**: Default driver for local filesystem storage
  # - **nfs**: Network File System driver for shared storage
  # - **cifs**: Common Internet File System driver
  # - **rexray**: REX-Ray driver for cloud storage integration
  # - **convoy**: Convoy driver for snapshot management
  #
  # == Example Usage
  #
  #   # Create basic local volume
  #   response = CreateVolume.call(
  #     server_context: context,
  #     name: "app-data"
  #   )
  #
  #   # Create volume with specific driver
  #   response = CreateVolume.call(
  #     server_context: context,
  #     name: "shared-storage",
  #     driver: "nfs"
  #   )
  #
  #   # Create database volume
  #   response = CreateVolume.call(
  #     server_context: context,
  #     name: "postgres-data",
  #     driver: "local"
  #   )
  #
  # @see Docker::Volume.create
  # @since 0.1.0
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
