# frozen_string_literal: true

module DockerMCP
  class TagImage < MCP::Tool
    description 'Tag a Docker image'

    input_schema(
      properties: {
        id: {
          type: 'string',
          description: 'Image ID or current name:tag'
        },
        repo: {
          type: 'string',
          description: 'Repository name (e.g., "username/imagename" or "registry/username/imagename")'
        },
        tag: {
          type: 'string',
          description: 'Tag for the image (default: "latest")'
        },
        force: {
          type: 'boolean',
          description: 'Force tag even if it already exists (default: true)'
        }
      },
      required: %w[id repo]
    )

    def self.call(id:, repo:, server_context:, tag: 'latest', force: true)
      image = Docker::Image.get(id)

      image.tag('repo' => repo, 'tag' => tag, 'force' => force)

      MCP::Tool::Response.new([{
                                type: 'text',
                                text: "Image tagged successfully as #{repo}:#{tag}"
                              }])
    rescue Docker::Error::NotFoundError
      MCP::Tool::Response.new([{
                                type: 'text',
                                text: "Image #{id} not found"
                              }])
    rescue StandardError => e
      MCP::Tool::Response.new([{
                                type: 'text',
                                text: "Error tagging image: #{e.message}"
                              }])
    end
  end
end
