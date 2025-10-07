# frozen_string_literal: true

module DockerMCP
  # MCP tool for creating Docker volumes.
  #
  # This tool provides the ability to create persistent Docker volumes for
  # data storage that survives container lifecycle events. Volumes are the
  # preferred mechanism for persisting data generated and used by Docker
  # containers.
  #
  # == Features
  #
  # - Create named persistent volumes
  # - Support for different volume drivers
  # - Comprehensive error handling
  # - Duplicate name detection
  # - Flexible storage configuration
  #
  # == Volume Drivers
  #
  # Docker supports various volume drivers:
  # - **local**: Default driver using host filesystem
  # - **nfs**: Network File System for shared storage
  # - **cifs**: Common Internet File System
  # - **rexray**: External storage orchestration
  # - **Custom**: Third-party volume drivers
  #
  # == Persistence Benefits
  #
  # Docker volumes provide several advantages:
  # - **Data Persistence**: Survive container deletion and recreation
  # - **Performance**: Better performance than bind mounts on Docker Desktop
  # - **Portability**: Can be moved between containers and hosts
  # - **Backup**: Easier to backup and restore than container filesystems
  # - **Sharing**: Can be shared between multiple containers
  # - **Management**: Managed by Docker daemon with proper lifecycle
  #
  # == Security Considerations
  #
  # Volume creation affects data security:
  # - **Data Isolation**: Volumes provide isolation between containers
  # - **Access Control**: Volume permissions affect data access
  # - **Storage Location**: Local volumes stored on host filesystem
  # - **Shared Access**: Multiple containers can access the same volume
  #
  # Security implications:
  # - Volumes persist data beyond container lifecycle
  # - Volume names may reveal application details
  # - Shared volumes can leak data between containers
  # - Storage driver choice affects security properties
  #
  # Best practices:
  # - Use descriptive but not sensitive volume names
  # - Implement proper volume access controls
  # - Regular backup of critical volume data
  # - Monitor volume usage and access patterns
  # - Choose appropriate drivers for security requirements
  #
  # == Example Usage
  #
  #   # Create basic local volume
  #   CreateVolume.call(
  #     server_context: context,
  #     name: "app-data"
  #   )
  #
  #   # Create volume with specific driver
  #   CreateVolume.call(
  #     server_context: context,
  #     name: "shared-storage",
  #     driver: "nfs"
  #   )
  #
  # @see ListVolumes
  # @see RemoveVolume
  # @see Docker::Volume.create
  # @since 0.1.0
  class CreateVolume < MCP::Tool
    description 'Create a Docker volume'

    input_schema(
      properties: {
        name: {
          type: 'string',
          description: 'Name of the volume'
        },
        driver: {
          type: 'string',
          description: 'Driver to use (default: local)'
        }
      },
      required: ['name']
    )

    # Create a new Docker volume for persistent data storage.
    #
    # This method creates a named Docker volume that can be used by containers
    # for persistent data storage. The volume will survive container deletion
    # and can be shared between multiple containers.
    #
    # @param name [String] name for the new volume
    # @param server_context [Object] MCP server context (unused but required)
    # @param driver [String] volume driver to use (default: "local")
    #
    # @return [MCP::Tool::Response] volume creation results
    #
    # @raise [Docker::Error::ConflictError] if volume name already exists
    # @raise [StandardError] for other volume creation failures
    #
    # @example Create application data volume
    #   response = CreateVolume.call(
    #     server_context: context,
    #     name: "webapp-data"
    #   )
    #
    # @example Create NFS volume
    #   response = CreateVolume.call(
    #     server_context: context,
    #     name: "shared-files",
    #     driver: "nfs"
    #   )
    #
    # @see Docker::Volume.create
    def self.call(name:, server_context:, driver: 'local')
      options = {
        'Name' => name,
        'Driver' => driver
      }

      Docker::Volume.create(name, options)

      MCP::Tool::Response.new([{
                                type: 'text',
                                text: "Volume #{name} created successfully"
                              }])
    rescue Docker::Error::ConflictError
      MCP::Tool::Response.new([{
                                type: 'text',
                                text: "Volume #{name} already exists"
                              }])
    rescue StandardError => e
      MCP::Tool::Response.new([{
                                type: 'text',
                                text: "Error creating volume: #{e.message}"
                              }])
    end
  end
end
