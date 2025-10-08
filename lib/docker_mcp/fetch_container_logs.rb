# frozen_string_literal: true

module DockerMCP
  # MCP tool for fetching Docker container logs.
  #
  # This tool retrieves log output from Docker containers, including both
  # standard output and standard error streams. It supports filtering by
  # stream type, limiting output length, timestamp inclusion, and retrieving
  # logs from both running and stopped containers.
  #
  # == Features
  #
  # - Fetch logs from running and stopped containers
  # - Separate or combined stdout and stderr streams
  # - Configurable output length limiting (tail functionality)
  # - Optional timestamp inclusion for log entries
  # - Support for container identification by ID or name
  # - Comprehensive error handling and status reporting
  #
  # == Security Considerations
  #
  # Container logs may contain sensitive information:
  # - **Application Data**: Database queries, API keys, user data
  # - **System Information**: Internal paths, configuration details
  # - **Error Details**: Stack traces revealing application internals
  # - **Access Patterns**: User behavior and system usage information
  # - **Debugging Information**: Temporary credentials or session data
  #
  # Implement proper access controls and data sanitization for log access.
  #
  # == Parameters
  #
  # - **id**: Container ID or name (required)
  # - **stdout**: Include stdout in logs (optional, default: true)
  # - **stderr**: Include stderr in logs (optional, default: true)
  # - **timestamps**: Show timestamps for log entries (optional, default: false)
  # - **tail**: Number of lines to show from end of logs (optional, default: all)
  #
  # == Example Usage
  #
  #   # Fetch all logs
  #   response = FetchContainerLogs.call(
  #     server_context: context,
  #     id: "web-server"
  #   )
  #
  #   # Fetch recent errors with timestamps
  #   response = FetchContainerLogs.call(
  #     server_context: context,
  #     id: "app-container",
  #     stdout: false,
  #     stderr: true,
  #     timestamps: true,
  #     tail: 100
  #   )
  #
  # @see Docker::Container#logs
  # @since 0.1.0
  FETCH_CONTAINER_LOGS_DEFINITION = ToolForge.define(:fetch_container_logs) do
    description 'Fetch Docker container logs'

    param :id,
          type: :string,
          description: 'Container ID or name'

    param :stdout,
          type: :boolean,
          description: 'Include stdout (default: true)',
          required: false,
          default: true

    param :stderr,
          type: :boolean,
          description: 'Include stderr (default: true)',
          required: false,
          default: true

    param :tail,
          type: :integer,
          description: 'Number of lines to show from the end of logs (default: all)',
          required: false

    param :timestamps,
          type: :boolean,
          description: 'Show timestamps (default: false)',
          required: false,
          default: false

    execute do |id:, stdout: true, stderr: true, tail: nil, timestamps: false|
      container = Docker::Container.get(id)

      options = {
        stdout: stdout,
        stderr: stderr,
        timestamps: timestamps
      }
      options[:tail] = tail if tail

      container.logs(options)
    rescue Docker::Error::NotFoundError
      "Container #{id} not found"
    rescue StandardError => e
      "Error fetching logs: #{e.message}"
    end
  end

  FetchContainerLogs = FETCH_CONTAINER_LOGS_DEFINITION.to_mcp_tool
end
