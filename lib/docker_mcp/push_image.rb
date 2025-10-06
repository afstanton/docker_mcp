# frozen_string_literal: true

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
      image = Docker::Image.get(name)

      options = {}
      options[:tag] = tag if tag
      options[:repo_tag] = repo_tag if repo_tag

      # Push returns the image with updated info
      image.push(nil, options)

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
