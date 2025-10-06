# frozen_string_literal: true

module DockerMCP
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
