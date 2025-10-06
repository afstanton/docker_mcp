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
      # If tag is provided separately, append it to from_image
      # If from_image already has a tag (contains :), use as-is
      # Otherwise default to :latest
      image_with_tag = if tag
                         "#{from_image}:#{tag}"
                       elsif from_image.include?(':')
                         from_image
                       else
                         "#{from_image}:latest"
                       end

      image = Docker::Image.create('fromImage' => image_with_tag)

      MCP::Tool::Response.new([{
                                type: 'text',
                                text: "Image #{image_with_tag} pulled successfully. ID: #{image.id}"
                              }])
    rescue Docker::Error::NotFoundError
      MCP::Tool::Response.new([{
                                type: 'text',
                                text: "Image #{image_with_tag} not found"
                              }])
    rescue StandardError => e
      MCP::Tool::Response.new([{
                                type: 'text',
                                text: "Error pulling image: #{e.message}"
                              }])
    end
  end
end
