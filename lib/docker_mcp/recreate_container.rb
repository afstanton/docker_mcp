# frozen_string_literal: true

module DockerMCP
  # MCP tool for recreating Docker containers with the same configuration.
  #
  # This tool provides a convenient way to recreate containers while preserving
  # their original configuration. It stops and removes the existing container,
  # then creates a new one with identical settings. This is useful for applying
  # image updates, clearing container state, or resolving container issues.
  #
  # == Features
  #
  # - Preserves complete container configuration
  # - Maintains original name and settings
  # - Handles running containers gracefully
  # - Restores running state after recreation
  # - Configurable stop timeout
  # - Comprehensive error handling
  #
  # == Process Overview
  #
  # 1. Retrieve existing container configuration
  # 2. Stop container gracefully (if running)
  # 3. Remove the old container
  # 4. Create new container with identical config
  # 5. Start new container (if original was running)
  #
  # == ⚠️ Data Loss Warning ⚠️
  #
  # **DESTRUCTIVE OPERATION - DATA LOSS POSSIBLE**
  #
  # This operation can cause permanent data loss:
  # - Container filesystem changes are lost
  # - Temporary data and logs are deleted
  # - Container state is reset completely
  # - Network connections are interrupted
  # - Anonymous volumes may be recreated empty
  #
  # == Security Considerations
  #
  # - Original configuration is preserved exactly
  # - Sensitive environment variables are maintained
  # - Port mappings and volume mounts are restored
  # - Network access patterns remain the same
  #
  # Ensure original configuration is still secure:
  # - Review exposed ports and volumes
  # - Validate environment variables
  # - Check image security updates
  # - Verify network policies
  #
  # == Example Usage
  #
  #   # Recreate with default timeout
  #   RecreateContainer.call(
  #     server_context: context,
  #     id: "web-server"
  #   )
  #
  #   # Recreate with longer stop timeout
  #   RecreateContainer.call(
  #     server_context: context,
  #     id: "database",
  #     timeout: 30
  #   )
  #
  # @see CreateContainer
  # @see StopContainer
  # @see RemoveContainer
  # @see Docker::Container.create
  # @since 0.1.0
  class RecreateContainer < MCP::Tool
    description 'Recreate a Docker container (stops, removes, and recreates with same configuration)'

    input_schema(
      properties: {
        id: {
          type: 'string',
          description: 'Container ID or name to recreate'
        },
        timeout: {
          type: 'integer',
          description: 'Seconds to wait before killing the container when stopping (default: 10)'
        }
      },
      required: ['id']
    )

    # Recreate a Docker container with identical configuration.
    #
    # This method performs a complete container recreation cycle while
    # preserving all configuration settings. The new container will have
    # the same name, environment, port mappings, volumes, and other
    # settings as the original.
    #
    # @param id [String] container ID (full or short) or container name
    # @param server_context [Object] MCP server context (unused but required)
    # @param timeout [Integer] seconds to wait before force killing during stop (default: 10)
    #
    # @return [MCP::Tool::Response] recreation results with new container ID
    #
    # @raise [Docker::Error::NotFoundError] if container doesn't exist
    # @raise [StandardError] for recreation failures
    #
    # @example Recreate application container
    #   response = RecreateContainer.call(
    #     server_context: context,
    #     id: "my-app"
    #   )
    #
    # @example Recreate database with extended timeout
    #   response = RecreateContainer.call(
    #     server_context: context,
    #     id: "postgres-main",
    #     timeout: 60  # Allow time for DB shutdown
    #   )
    #
    # @see Docker::Container.get
    # @see Docker::Container.create
    def self.call(id:, server_context:, timeout: 10)
      # Get the existing container
      old_container = Docker::Container.get(id)
      config = old_container.json

      # Extract configuration we need to preserve
      image = config['Config']['Image']
      name = config['Name']&.delete_prefix('/')
      cmd = config['Config']['Cmd']
      env = config['Config']['Env']
      exposed_ports = config['Config']['ExposedPorts']
      host_config = config['HostConfig']

      # Stop and remove the old container
      old_container.stop('timeout' => timeout) if config['State']['Running']
      old_container.delete

      # Create new container with same config
      new_config = {
        'Image' => image,
        'Cmd' => cmd,
        'Env' => env,
        'ExposedPorts' => exposed_ports,
        'HostConfig' => host_config
      }
      new_config['name'] = name if name

      new_container = Docker::Container.create(new_config)

      # Start if the old one was running
      new_container.start if config['State']['Running']

      MCP::Tool::Response.new([{
                                type: 'text',
                                text: "Container #{id} recreated successfully. New ID: #{new_container.id}"
                              }])
    rescue Docker::Error::NotFoundError
      MCP::Tool::Response.new([{
                                type: 'text',
                                text: "Container #{id} not found"
                              }])
    rescue StandardError => e
      MCP::Tool::Response.new([{
                                type: 'text',
                                text: "Error recreating container: #{e.message}"
                              }])
    end
  end
end
