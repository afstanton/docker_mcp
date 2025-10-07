# frozen_string_literal: true

module DockerMCP
  class ExecContainer < MCP::Tool
    description 'Execute a command inside a running Docker container. ' \
                'WARNING: This provides arbitrary command execution within the container. ' \
                'Ensure proper security measures are in place.'

    input_schema(
      properties: {
        id: {
          type: 'string',
          description: 'Container ID or name'
        },
        cmd: {
          type: 'string',
          description: 'Command to execute (e.g., "ls -la /app" or "python script.py")'
        },
        working_dir: {
          type: 'string',
          description: 'Working directory for the command (optional)'
        },
        user: {
          type: 'string',
          description: 'User to run the command as (optional, e.g., "1000" or "username")'
        },
        env: {
          type: 'array',
          items: { type: 'string' },
          description: 'Environment variables as KEY=VALUE (optional)'
        },
        stdin: {
          type: 'string',
          description: 'Input to send to the command via stdin (optional)'
        },
        timeout: {
          type: 'integer',
          description: 'Timeout in seconds (optional, default: 60)'
        }
      },
      required: %w[id cmd]
    )

    def self.call(id:, cmd:, server_context:, working_dir: nil, user: nil,
                  env: nil, stdin: nil, timeout: 60)
      container = Docker::Container.get(id)

      # Parse command string into array
      # Simple shell-like parsing: split on spaces but respect quoted strings

      cmd_array = Shellwords.split(cmd)

      # Build exec options
      exec_options = {
        'Cmd' => cmd_array,
        'AttachStdout' => true,
        'AttachStderr' => true
      }
      exec_options['WorkingDir'] = working_dir if working_dir
      exec_options['User'] = user if user
      exec_options['Env'] = env if env
      exec_options['AttachStdin'] = true if stdin

      # Execute the command
      stdout_data = []
      stderr_data = []
      exit_code = nil

      begin
        # Use container.exec which returns [stdout, stderr, exit_code]
        result = if stdin
                   container.exec(cmd_array, stdin: StringIO.new(stdin), wait: timeout)
                 else
                   container.exec(cmd_array, wait: timeout)
                 end

        stdout_data = result[0]
        stderr_data = result[1]
        exit_code = result[2]
      rescue Docker::Error::TimeoutError
        return MCP::Tool::Response.new([{
                                         type: 'text',
                                         text: "Command execution timed out after #{timeout} seconds"
                                       }])
      end

      # Format response
      response_text = "Command executed in container #{id}\n"
      response_text += "Exit code: #{exit_code}\n\n"

      if stdout_data && !stdout_data.empty?
        stdout_str = stdout_data.join
        response_text += "STDOUT:\n#{stdout_str}\n" unless stdout_str.strip.empty?
      end

      if stderr_data && !stderr_data.empty?
        stderr_str = stderr_data.join
        response_text += "\nSTDERR:\n#{stderr_str}\n" unless stderr_str.strip.empty?
      end

      MCP::Tool::Response.new([{
                                type: 'text',
                                text: response_text.strip
                              }])
    rescue Docker::Error::NotFoundError
      MCP::Tool::Response.new([{
                                type: 'text',
                                text: "Container #{id} not found"
                              }])
    rescue StandardError => e
      MCP::Tool::Response.new([{
                                type: 'text',
                                text: "Error executing command: #{e.message}"
                              }])
    end
  end
end
