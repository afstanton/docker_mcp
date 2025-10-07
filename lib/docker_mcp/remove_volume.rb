# frozen_string_literal: true

module DockerMCP
  # MCP tool for removing Docker volumes.
  #
  # This tool provides the ability to permanently delete Docker volumes from
  # the system. This is a destructive operation that will permanently delete
  # all data stored in the volume.
  #
  # == Features
  #
  # - Remove Docker volumes by name
  # - Force removal option for volumes in use
  # - Comprehensive error handling
  # - Dependency checking (prevents removal if containers are using the volume)
  # - Safe cleanup of storage resources
  #
  # == ⚠️ CRITICAL DATA LOSS WARNING ⚠️
  #
  # **DESTRUCTIVE OPERATION - PERMANENT DATA LOSS**
  #
  # This operation permanently and irreversibly deletes data:
  # - **ALL DATA** in the volume is deleted forever
  # - No recovery possible after deletion
  # - Applications may lose critical data
  # - Databases and persistent state are destroyed
  # - Configuration files and user data are lost
  # - Operation cannot be undone
  #
  # == Volume Dependencies
  #
  # Volumes may have active dependencies:
  # - **Running Containers**: Containers currently using the volume
  # - **Stopped Containers**: Containers that could be restarted
  # - **Application Data**: Critical application state and databases
  # - **User Data**: User-generated content and files
  #
  # == Security Considerations
  #
  # Volume removal has security implications:
  # - Sensitive data is not securely wiped
  # - Data may be recoverable from disk sectors
  # - Shared volumes may affect multiple applications
  # - Removal logs may reveal data existence
  #
  # Critical security measures:
  # - **Backup critical data** before removal
  # - Verify no containers depend on the volume
  # - Consider secure data wiping for sensitive volumes
  # - Audit volume removal operations
  # - Monitor for unauthorized volume deletions
  #
  # == Force Removal Risks
  #
  # Force removal bypasses safety checks:
  # - Removes volumes even if containers are using them
  # - Can cause immediate application failures
  # - May corrupt running applications
  # - Data loss occurs immediately
  #
  # == Example Usage
  #
  #   # Safe removal of unused volume
  #   RemoveVolume.call(
  #     server_context: context,
  #     name: "temp-data"
  #   )
  #
  #   # Force removal of volume in use (DANGEROUS)
  #   RemoveVolume.call(
  #     server_context: context,
  #     name: "stuck-volume",
  #     force: true
  #   )
  #
  # @see CreateVolume
  # @see ListVolumes
  # @see Docker::Volume#remove
  # @since 0.1.0
  class RemoveVolume < MCP::Tool
    description 'Remove a Docker volume'

    input_schema(
      properties: {
        name: {
          type: 'string',
          description: 'Volume name'
        },
        force: {
          type: 'boolean',
          description: 'Force removal of the volume (default: false)'
        }
      },
      required: ['name']
    )

    # Remove a Docker volume permanently from the system.
    #
    # This method permanently deletes the specified volume and all data
    # contained within it. By default, it performs safety checks to prevent
    # removal of volumes with active container dependencies.
    #
    # @param name [String] name of the volume to remove
    # @param server_context [Object] MCP server context (unused but required)
    # @param force [Boolean] whether to force removal despite dependencies (default: false)
    #
    # @return [MCP::Tool::Response] removal operation results
    #
    # @raise [Docker::Error::NotFoundError] if volume doesn't exist
    # @raise [StandardError] for removal failures or dependency conflicts
    #
    # @example Remove unused volume
    #   response = RemoveVolume.call(
    #     server_context: context,
    #     name: "old-cache-data"
    #   )
    #
    # @example Force remove problematic volume
    #   response = RemoveVolume.call(
    #     server_context: context,
    #     name: "corrupted-volume",
    #     force: true
    #   )
    #
    # @see Docker::Volume#remove
    def self.call(name:, server_context:, force: false)
      volume = Docker::Volume.get(name)
      volume.remove(force: force)

      MCP::Tool::Response.new([{
                                type: 'text',
                                text: "Volume #{name} removed successfully"
                              }])
    rescue Docker::Error::NotFoundError
      MCP::Tool::Response.new([{
                                type: 'text',
                                text: "Volume #{name} not found"
                              }])
    rescue StandardError => e
      MCP::Tool::Response.new([{
                                type: 'text',
                                text: "Error removing volume: #{e.message}"
                              }])
    end
  end
end
