# frozen_string_literal: true

require 'json'

module DockerMCP
  class PushImage < MCP::Tool
    description 'Push a Docker image'

    input_schema(
      properties: {
        name: {
          type: 'string',
          description: 'Image name or ID to push'
        },
        tag: {
          type: 'string',
          description: 'Tag to push (optional, pushes all tags if not specified)'
        },
        repo_tag: {
          type: 'string',
          description: 'Full repo:tag to push (e.g., "registry/repo:tag") (optional)'
        }
      },
      required: ['name']
    )

    def self.call(name:, server_context:, tag: nil, repo_tag: nil)
      # Construct the full image identifier to look up
      image_identifier = tag ? "#{name}:#{tag}" : name

      # Validate that the image name includes a registry/username
      # Images without a registry prefix will fail to push to Docker Hub
      unless name.include?('/') || repo_tag&.include?('/')
        error_msg = 'Error: Image name must include registry/username ' \
                    "(e.g., 'username/#{name}'). Local images cannot be " \
                    'pushed without a registry prefix.'
        return MCP::Tool::Response.new([{
                                         type: 'text',
                                         text: error_msg
                                       }])
      end

      # Get the image after validation
      image = Docker::Image.get(image_identifier)

      # Read Docker credentials and authenticate
      # The docker-api gem requires explicit authentication via Docker.authenticate!
      # Docker uses credential helpers to store credentials securely
      begin
        config_path = File.expand_path('~/.docker/config.json')
        if File.exist?(config_path)
          config = JSON.parse(File.read(config_path))

          # Check if a credential helper is configured
          if config['credsStore']
            helper_name = "docker-credential-#{config['credsStore']}"

            # Call the credential helper to get credentials for Docker Hub
            server_url = 'https://index.docker.io/v1/'
            creds_json = `echo "#{server_url}" | #{helper_name} get 2>/dev/null`

            if $CHILD_STATUS.success? && !creds_json.empty?
              creds_data = JSON.parse(creds_json)
              # Authenticate with Docker using the retrieved credentials
              Docker.authenticate!(
                'username' => creds_data['Username'],
                'password' => creds_data['Secret'],
                'serveraddress' => server_url
              )
            end
          elsif config['auths'] && config['auths']['https://index.docker.io/v1/']
            # Fallback: try direct auth from config if no credential helper
            auth_data = config['auths']['https://index.docker.io/v1/']
            Docker.authenticate!('serveraddress' => 'https://index.docker.io/v1/') if auth_data
          end
        end
      rescue StandardError => _e
        # If authentication setup fails, continue anyway
        # We'll catch the real error during push
      end

      options = {}
      options[:tag] = tag if tag
      options[:repo_tag] = repo_tag if repo_tag

      # Get credentials
      creds = Docker.creds

      # Push and capture the response
      image.push(creds, options) do |chunk|
        # The push method yields JSON chunks with status info
        # We can parse these to detect errors
        if chunk
          parsed = begin
            JSON.parse(chunk)
          rescue StandardError
            nil
          end
          raise Docker::Error::DockerError, parsed['error'] if parsed && parsed['error']
        end
      end

      push_target = repo_tag || (tag ? "#{name}:#{tag}" : name)

      MCP::Tool::Response.new([{
                                type: 'text',
                                text: "Image #{push_target} pushed successfully"
                              }])
    rescue Docker::Error::NotFoundError
      MCP::Tool::Response.new([{
                                type: 'text',
                                text: "Image #{name} not found"
                              }])
    rescue Docker::Error::AuthenticationError
      MCP::Tool::Response.new([{
                                type: 'text',
                                text: "Authentication failed. Please authenticate with 'docker login' first"
                              }])
    rescue StandardError => e
      MCP::Tool::Response.new([{
                                type: 'text',
                                text: "Error pushing image: #{e.message}"
                              }])
    end
  end
end
