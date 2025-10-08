# frozen_string_literal: true

module DockerMCP
  # MCP tool for listing Docker volumes.
  #
  # This tool provides comprehensive information about all Docker volumes
  # configured on the system. It returns detailed volume metadata including
  # mount points, drivers, usage statistics, and associated containers.
  #
  # == Features
  #
  # - Lists all Docker volumes (named and anonymous)
  # - Provides detailed volume metadata
  # - Shows mount points and storage locations
  # - Displays driver information and options
  # - Includes creation timestamps and labels
  # - Reports volume scope and capabilities
  #
  # == Security Considerations
  #
  # Volume information can reveal sensitive details about:
  # - **Data Storage**: Persistent data locations and structures
  # - **File System Access**: Mount points and storage paths
  # - **Container Dependencies**: Volume usage patterns
  # - **Data Persistence**: Backup and recovery points
  #
  # Monitor access to this tool and implement appropriate controls.
  #
  # == Return Format
  #
  # Returns an array of volume objects with comprehensive metadata:
  # - Volume names and mount points
  # - Driver types and configurations
  # - Creation timestamps
  # - Labels and options
  # - Scope information
  # - Storage usage details
  #
  # == Example Usage
  #
  #   volumes = ListVolumes.call(server_context: context)
  #   volumes.each do |volume|
  #     puts "#{volume['Name']}: #{volume['Mountpoint']}"
  #   end
  #
  # @see Docker::Volume.all
  # @since 0.1.0
  LIST_VOLUMES_DEFINITION = ToolForge.define(:list_volumes) do
    description 'List Docker volumes'

    execute do
      Docker::Volume.all.map(&:info)
    end
  end

  ListVolumes = LIST_VOLUMES_DEFINITION.to_mcp_tool
end
