# frozen_string_literal: true

module DockerMCP
  class BuildImage < MCP::Tool
    description 'Build a Docker image'

    input_schema(
      properties: {
        dockerfile: {
          type: 'string',
          description: 'Dockerfile content as a string'
        },
        tag: {
          type: 'string',
          description: 'Tag for the built image (e.g., "myimage:latest")'
        }
      },
      required: ['dockerfile']
    )

    def self.call(dockerfile:, server_context:, tag: nil)
      options = {}
      options['t'] = tag if tag

      image = Docker::Image.build(dockerfile, options)

      response_text = "Image built successfully. ID: #{image.id}"
      response_text += ", Tag: #{tag}" if tag

      MCP::Tool::Response.new([{
                                type: 'text',
                                text: response_text
                              }])
    rescue StandardError => e
      MCP::Tool::Response.new([{
                                type: 'text',
                                text: "Error building image: #{e.message}"
                              }])
    end
  end
end
