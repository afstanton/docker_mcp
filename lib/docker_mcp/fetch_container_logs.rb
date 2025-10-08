# frozen_string_literal: true

module DockerMCP
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
