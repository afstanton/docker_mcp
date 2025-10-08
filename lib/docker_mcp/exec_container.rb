# frozen_string_literal: true

module DockerMCP
  # MCP tool for executing commands inside Docker containers.
  #
  # This tool provides the ability to execute arbitrary commands inside
  # running Docker containers. It supports interactive and non-interactive
  # execution, environment variable injection, working directory specification,
  # and user context switching within the container.
  #
  # == Features
  #
  # - Execute arbitrary commands in running containers
  # - Support for command arguments and shell parsing
  # - Environment variable injection
  # - Working directory specification
  # - User context switching (run as specific user)
  # - Standard input, output, and error handling
  # - Configurable execution timeouts
  #
  # == Security Considerations
  #
  # **CRITICAL WARNING**: This tool provides arbitrary command execution
  # capabilities with significant security implications:
  #
  # - **Code Execution**: Can run any command available in the container
  # - **File System Access**: Can read, write, and modify container files
  # - **Network Access**: Can initiate network connections from container
  # - **Process Manipulation**: Can start, stop, and signal processes
  # - **Data Exposure**: Can access sensitive data within the container
  # - **Privilege Escalation**: May exploit container or kernel vulnerabilities
  # - **Resource Consumption**: Can consume container and host resources
  #
  # **Security Recommendations**:
  # - Implement strict access controls and authentication
  # - Use dedicated execution containers with minimal privileges
  # - Monitor and log all command executions
  # - Apply resource limits and timeouts
  # - Validate and sanitize all command inputs
  # - Consider using read-only file systems where possible
  # - Implement network segmentation for container environments
  #
  # == Parameters
  #
  # - **id**: Container ID or name (required)
  # - **cmd**: Command to execute (shell-parsed into arguments) (required)
  # - **working_dir**: Working directory for command execution (optional)
  # - **user**: User to run the command as (optional, e.g., "1000" or "username")
  # - **env**: Environment variables as comma-separated KEY=VALUE pairs (optional)
  # - **stdin**: Input to send to command via stdin (optional)
  # - **timeout**: Timeout in seconds (optional, default: 60)
  #
  # == Example Usage
  #
  #   # Basic command execution
  #   response = ExecContainer.call(
  #     server_context: context,
  #     id: "web-container",
  #     cmd: "nginx -t"
  #   )
  #
  #   # Advanced execution with environment
  #   response = ExecContainer.call(
  #     server_context: context,
  #     id: "app-container",
  #     cmd: "bundle exec rails console",
  #     working_dir: "/app",
  #     user: "rails",
  #     env: "RAILS_ENV=production,DEBUG=true",
  #     timeout: 300
  #   )
  #
  # @see Docker::Container#exec
  # @since 0.1.0
  EXEC_CONTAINER_DEFINITION = ToolForge.define(:exec_container) do
    description 'Execute a command inside a running Docker container. ' \
                'WARNING: This provides arbitrary command execution within the container. ' \
                'Ensure proper security measures are in place.'

    param :id,
          type: :string,
          description: 'Container ID or name'

    param :cmd,
          type: :string,
          description: 'Command to execute (e.g., "ls -la /app" or "python script.py")'

    param :working_dir,
          type: :string,
          description: 'Working directory for the command (optional)',
          required: false

    param :user,
          type: :string,
          description: 'User to run the command as (optional, e.g., "1000" or "username")',
          required: false

    param :env,
          type: :string,
          description: 'Environment variables as comma-separated KEY=VALUE pairs (optional)',
          required: false

    param :stdin,
          type: :string,
          description: 'Input to send to the command via stdin (optional)',
          required: false

    param :timeout,
          type: :integer,
          description: 'Timeout in seconds (optional, default: 60)',
          required: false,
          default: 60

    execute do |id:, cmd:, working_dir: nil, user: nil, env: nil, stdin: nil, timeout: 60|
      container = Docker::Container.get(id)

      # Parse command string into array
      cmd_array = Shellwords.split(cmd)

      # Parse environment variables from comma-separated string to array
      env.split(',').map(&:strip) if env && !env.empty?

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
        return "Command execution timed out after #{timeout} seconds"
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

      response_text.strip
    rescue Docker::Error::NotFoundError
      "Container #{id} not found"
    rescue StandardError => e
      "Error executing command: #{e.message}"
    end
  end

  ExecContainer = EXEC_CONTAINER_DEFINITION.to_mcp_tool
end
