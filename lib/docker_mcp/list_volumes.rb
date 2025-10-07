# frozen_string_literal: true

module DockerMCP
  # MCP tool for listing Docker volumes.
  #
  # This tool provides functionality to list all Docker volumes on the system,
  # including both named volumes and anonymous volumes. It returns comprehensive
  # information about volume configuration, drivers, mount points, and usage.
  #
  # == Features
  #
  # - List all Docker volumes on the system
  # - Comprehensive volume metadata
  # - No configuration required
  # - Read-only operation
  # - Includes named and anonymous volumes
  #
  # == Volume Information Included
  #
  # The response typically includes:
  # - **Volume Name**: Unique identifier for the volume
  # - **Driver**: Volume driver (local, nfs, etc.)
  # - **Mountpoint**: Physical location on host filesystem
  # - **Labels**: User-defined metadata labels
  # - **Options**: Driver-specific configuration options
  # - **Scope**: Volume scope (local, global)
  # - **CreatedAt**: Volume creation timestamp
  #
  # == Volume Types
  #
  # Docker manages different types of volumes:
  # - **Named Volumes**: User-created persistent volumes
  # - **Anonymous Volumes**: Automatically created temporary volumes
  # - **Bind Mounts**: Direct host directory mounts (not shown in volume list)
  # - **tmpfs Mounts**: Memory-based temporary filesystems (not shown)
  #
  # == Security Considerations
  #
  # This is a read-only operation that reveals storage information:
  # - Exposes data storage architecture
  # - Shows volume naming patterns
  # - May reveal application data locations
  # - Could aid in data discovery attacks
  #
  # While generally safe, consider access control:
  # - Limit exposure of volume inventory
  # - Be cautious with sensitive volume names
  # - Monitor for unauthorized volume discovery
  # - Consider data classification implications
  #
  # == Example Usage
  #
  #   # List all volumes
  #   ListVolumes.call(server_context: context)
  #
  # @example Usage in data management
  #   # Get available volumes before container creation
  #   volumes_response = ListVolumes.call(server_context: context)
  #   # Use volume information to select appropriate storage
  #
  # @see CreateVolume
  # @see RemoveVolume
  # @see Docker::Volume.all
  # @since 0.1.0
  class ListVolumes < MCP::Tool
    description 'List Docker volumes'

    # List all Docker volumes available on the system.
    #
    # This method retrieves information about all Docker volumes, including
    # both named volumes created by users and anonymous volumes created
    # automatically by containers. The information includes comprehensive
    # metadata for each volume.
    #
    # @param args [Array] variable arguments (unused but accepted for compatibility)
    #
    # @return [MCP::Tool::Response] comprehensive volume information
    #
    # @example List all volumes
    #   response = ListVolumes.call
    #   # Returns detailed info for all Docker volumes
    #
    # @see Docker::Volume.all
    def self.call(*)
      MCP::Tool::Response.new([{
                                type: 'text',
                                text: Docker::Volume.all.map(&:info).to_s
                              }])
    end
  end
end
