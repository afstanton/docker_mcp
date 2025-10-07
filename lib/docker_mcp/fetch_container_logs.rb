# frozen_string_literal: true

module DockerMCP
  # MCP tool for retrieving Docker container logs.
  #
  # This tool provides access to container logs with flexible filtering and
  # formatting options. It can retrieve both stdout and stderr logs with
  # optional timestamps and tail functionality for recent entries.
  #
  # == Features
  #
  # - Retrieve stdout and/or stderr logs
  # - Optional timestamp inclusion
  # - Tail functionality for recent logs
  # - Flexible log stream selection
  # - Comprehensive error handling
  # - Works with any container state
  #
  # == Log Sources
  #
  # Docker containers can generate logs from multiple sources:
  # - **stdout**: Standard output from container processes
  # - **stderr**: Standard error from container processes
  # - **timestamps**: Docker-generated timestamps for each log line
  #
  # == Security Considerations
  #
  # Container logs may contain sensitive information:
  # - Application secrets and API keys
  # - User data and personal information
  # - Internal system information
  # - Database connection strings
  # - Error messages with stack traces
  #
  # Security recommendations:
  # - Review log content before sharing
  # - Limit access to container logs
  # - Sanitize logs in production environments
  # - Use log rotation to manage log size
  # - Be cautious with log forwarding
  #
  # == Example Usage
  #
  #   # Get all logs
  #   FetchContainerLogs.call(
  #     server_context: context,
  #     id: "web-server"
  #   )
  #
  #   # Get recent logs with timestamps
  #   FetchContainerLogs.call(
  #     server_context: context,
  #     id: "app-container",
  #     tail: 100,
  #     timestamps: true
  #   )
  #
  #   # Get only error logs
  #   FetchContainerLogs.call(
  #     server_context: context,
  #     id: "database",
  #     stdout: false,
  #     stderr: true
  #   )
  #
  # @see ExecContainer
  # @see Docker::Container#logs
  # @since 0.1.0
  class FetchContainerLogs < MCP::Tool
    description 'Fetch Docker container logs'

    input_schema(
      properties: {
        id: {
          type: 'string',
          description: 'Container ID or name'
        },
        stdout: {
          type: 'boolean',
          description: 'Include stdout (default: true)'
        },
        stderr: {
          type: 'boolean',
          description: 'Include stderr (default: true)'
        },
        tail: {
          type: 'integer',
          description: 'Number of lines to show from the end of logs (default: all)'
        },
        timestamps: {
          type: 'boolean',
          description: 'Show timestamps (default: false)'
        }
      },
      required: ['id']
    )

    # Retrieve logs from a Docker container.
    #
    # This method fetches logs from the specified container with configurable
    # options for log sources (stdout/stderr), formatting (timestamps), and
    # quantity (tail). The logs are returned as a text response.
    #
    # @param id [String] container ID (full or short) or container name
    # @param server_context [Object] MCP server context (unused but required)
    # @param stdout [Boolean] whether to include stdout logs (default: true)
    # @param stderr [Boolean] whether to include stderr logs (default: true)
    # @param tail [Integer, nil] number of recent lines to return (nil for all)
    # @param timestamps [Boolean] whether to include timestamps (default: false)
    #
    # @return [MCP::Tool::Response] container logs as text
    #
    # @raise [Docker::Error::NotFoundError] if container doesn't exist
    # @raise [StandardError] for other log retrieval failures
    #
    # @example Get all logs
    #   response = FetchContainerLogs.call(
    #     server_context: context,
    #     id: "nginx-server"
    #   )
    #
    # @example Get recent error logs with timestamps
    #   response = FetchContainerLogs.call(
    #     server_context: context,
    #     id: "app-container",
    #     stdout: false,
    #     stderr: true,
    #     tail: 50,
    #     timestamps: true
    #   )
    #
    # @see Docker::Container#logs
    def self.call(id:, server_context:, stdout: true, stderr: true, tail: nil, timestamps: false)
      container = Docker::Container.get(id)

      options = {
        stdout: stdout,
        stderr: stderr,
        timestamps: timestamps
      }
      options[:tail] = tail if tail

      logs = container.logs(options)

      MCP::Tool::Response.new([{
                                type: 'text',
                                text: logs
                              }])
    rescue Docker::Error::NotFoundError
      MCP::Tool::Response.new([{
                                type: 'text',
                                text: "Container #{id} not found"
                              }])
    rescue StandardError => e
      MCP::Tool::Response.new([{
                                type: 'text',
                                text: "Error fetching logs: #{e.message}"
                              }])
    end
  end
end
