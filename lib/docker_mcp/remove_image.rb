# frozen_string_literal: true

module DockerMCP
  class RemoveImage < MCP::Tool
    description 'Remove a Docker image'

    input_schema(
      properties: {
        id: {
          type: 'string',
          description: 'Image ID, name, or name:tag'
        },
        force: {
          type: 'boolean',
          description: 'Force removal of the image (default: false)'
        },
        noprune: {
          type: 'boolean',
          description: 'Do not delete untagged parents (default: false)'
        }
      },
      required: ['id']
    )

    def self.call(id:, server_context:, force: false, noprune: false)
      image = Docker::Image.get(id)
      image.remove(force: force, noprune: noprune)

      MCP::Tool::Response.new([{
                                type: 'text',
                                text: "Image #{id} removed successfully"
                              }])
    rescue Docker::Error::NotFoundError
      MCP::Tool::Response.new([{
                                type: 'text',
                                text: "Image #{id} not found"
                              }])
    rescue StandardError => e
      MCP::Tool::Response.new([{
                                type: 'text',
                                text: "Error removing image: #{e.message}"
                              }])
    end
  end
end
