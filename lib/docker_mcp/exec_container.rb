# frozen_string_literal: true

module DockerMCP
  # MCP tool for executing commands inside running Docker containers.
  #
  # This tool provides the ability to execute arbitrary commands inside running
  # Docker containers, with full control over execution environment including
  # working directory, user context, environment variables, and stdin input.
  #
  # == ⚠️ CRITICAL SECURITY WARNING ⚠️
  #
  # This tool is EXTREMELY DANGEROUS as it allows arbitrary command execution
  # within Docker containers. This can be used to:
  # - Execute malicious code inside containers
  # - Access sensitive data within container filesystems
  # - Escalate privileges if container is poorly configured
  # - Perform lateral movement within containerized environments
  # - Exfiltrate data from applications
  #
  # ONLY use this tool in trusted environments with proper security controls:
  # - Ensure containers run with minimal privileges
  # - Use read-only filesystems where possible
  # - Implement proper network segmentation
  # - Monitor and audit all command executions
  # - Never expose this tool to untrusted clients
  #
  # == Features
  #
  # - Execute commands with custom working directory
  # - Run commands as specific users
  # - Set custom environment variables
  # - Provide stdin input to commands
  # - Configurable timeout protection
  # - Comprehensive error handling
  # - Separate stdout/stderr capture
  #
  # == Example Usage
  #
  #   # Simple command execution
  #   ExecContainer.call(
  #     server_context: context,
  #     id: "my-container",
  #     cmd: "ls -la /app"
  #   )
  #
  #   # Advanced execution with custom environment
  #   ExecContainer.call(
  #     server_context: context,
  #     id: "web-server",
  #     cmd: "python manage.py migrate",
  #     working_dir: "/app",
  #     user: "appuser",
  #     env: ["DJANGO_ENV=production", "DEBUG=false"],
  #     timeout: 120
  #   )
  #
  # @see Docker::Container#exec
  # @since 0.1.0
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

    # Execute a command inside a running Docker container.
    #
    # This method provides comprehensive command execution capabilities within
    # Docker containers, including advanced features like custom user context,
    # environment variables, working directory, and stdin input.
    #
    # The command is parsed using shell-like syntax with support for quoted
    # arguments. Output is captured separately for stdout and stderr, and
    # the exit code is reported.
    #
    # @param id [String] container ID or name to execute command in
    # @param cmd [String] command to execute (shell-parsed into arguments)
    # @param server_context [Object] MCP server context (unused but required)
    # @param working_dir [String, nil] working directory for command execution
    # @param user [String, nil] user to run command as (username or UID)
    # @param env [Array<String>, nil] environment variables in KEY=VALUE format
    # @param stdin [String, nil] input to send to command via stdin
    # @param timeout [Integer] maximum execution time in seconds (default: 60)
    #
    # @return [MCP::Tool::Response] execution results including stdout, stderr, and exit code
    #
    # @raise [Docker::Error::NotFoundError] if container doesn't exist
    # @raise [Docker::Error::TimeoutError] if execution exceeds timeout
    # @raise [StandardError] for other execution failures
    #
    # @example Basic command execution
    #   response = ExecContainer.call(
    #     server_context: context,
    #     id: "web-container",
    #     cmd: "nginx -t"
    #   )
    #
    # @example Advanced execution with environment
    #   response = ExecContainer.call(
    #     server_context: context,
    #     id: "app-container",
    #     cmd: "bundle exec rails console",
    #     working_dir: "/app",
    #     user: "rails",
    #     env: ["RAILS_ENV=production"],
    #     timeout: 300
    #   )
    #
    # @see Docker::Container#exec
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
