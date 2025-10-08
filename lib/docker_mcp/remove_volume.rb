# frozen_string_literal: true

module DockerMCP
  # MCP tool for removing Docker volumes.
  #
  # This tool provides the ability to delete Docker volumes when they
  # are no longer needed. Volume removal is critical for preventing
  # storage leaks and maintaining clean Docker environments.
  #
  # == Features
  #
  # - Remove volumes by name
  # - Force removal of volumes in use
  # - Validation of volume existence
  # - Comprehensive error handling
  # - Safe volume cleanup procedures
  # - Prevention of accidental data loss
  #
  # == Security Considerations
  #
  # Volume removal involves critical data considerations:
  # - **Data Loss**: Removed volumes and their data are permanently deleted
  # - **Service Disruption**: Removing volumes can break running containers
  # - **Data Recovery**: Volume data cannot be recovered after removal
  # - **Container Dependencies**: Applications may fail without expected volumes
  # - **Storage Cleanup**: Improper removal can leave orphaned data
  # - **Backup Requirements**: Critical data should be backed up before removal
  #
  # **Security Recommendations**:
  # - Always backup critical data before volume removal
  # - Verify no containers are using the volume
  # - Use force option only when absolutely necessary
  # - Document volume removal in change management
  # - Implement volume lifecycle and retention policies
  # - Monitor storage usage after volume removal
  # - Consider data migration instead of removal
  #
  # == Parameters
  #
  # - **name**: Volume name (required)
  # - **force**: Force removal of the volume (optional, default: false)
  #
  # == Example Usage
  #
  #   # Remove unused volume
  #   response = RemoveVolume.call(
  #     server_context: context,
  #     name: "old-app-data"
  #   )
  #
  #   # Force remove volume in use
  #   response = RemoveVolume.call(
  #     server_context: context,
  #     name: "stuck-volume",
  #     force: true
  #   )
  #
  #   # Clean up test volumes
  #   response = RemoveVolume.call(
  #     server_context: context,
  #     name: "test-data-volume"
  #   )
  #
  # @see Docker::Volume#remove
  # @since 0.1.0
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
