# frozen_string_literal: true

module DockerMCP
  class PullImage < MCP::Tool
    description 'Pull a Docker image'

    input_schema(
      properties: {
        from_image: {
          type: 'string',
          description: 'Image name to pull (e.g., "ubuntu" or "ubuntu:22.04")'
        },
        tag: {
          type: 'string',
          description: 'Tag to pull (optional, defaults to "latest" if not specified in from_image)'
        }
      },
      required: ['from_image']
    )

    def self.call(from_image:, server_context:, tag: nil)
      params = { 'fromImage' => from_image }
      params['tag'] = tag if tag

      image = Docker::Image.create(params)

      MCP::Tool::Response.new([{
                                type: 'text',
                                text: "Image #{from_image}#{":#{tag}" if tag} pulled successfully. ID: #{image.id}"
                              }])
    rescue Docker::Error::NotFoundError
      MCP::Tool::Response.new([{
                                type: 'text',
                                text: "Image #{from_image}#{":#{tag}" if tag} not found"
                              }])
    rescue StandardError => e
      MCP::Tool::Response.new([{
                                type: 'text',
                                text: "Error pulling image: #{e.message}"
                              }])
    end
  end
end
