# frozen_string_literal: true

module DockerMCP
  # MCP tool for building Docker images from Dockerfile content.
  #
  # This tool provides the ability to build Docker images by providing Dockerfile
  # content as a string. It supports optional tagging of the resulting image for
  # easy identification and reuse.
  #
  # == Security Considerations
  #
  # Building Docker images can be potentially dangerous:
  # - Dockerfile commands execute with Docker daemon privileges
  # - Images can contain malicious software or backdoors
  # - Build process can access host resources (network, files)
  # - Base images may contain vulnerabilities
  # - Build context may expose sensitive information
  #
  # Security recommendations:
  # - Review Dockerfile content carefully before building
  # - Use trusted base images from official repositories
  # - Scan built images for vulnerabilities
  # - Limit network access during builds
  # - Avoid including secrets in Dockerfile instructions
  # - Use multi-stage builds to minimize final image size
  #
  # == Features
  #
  # - Build images from Dockerfile content strings
  # - Optional image tagging during build
  # - Comprehensive error handling
  # - Support for all standard Dockerfile instructions
  # - Returns image ID and build status
  #
  # == Example Usage
  #
  #   # Simple image build
  #   BuildImage.call(
  #     server_context: context,
  #     dockerfile: "FROM alpine:latest\nRUN apk add --no-cache curl"
  #   )
  #
  #   # Build with custom tag
  #   BuildImage.call(
  #     server_context: context,
  #     dockerfile: dockerfile_content,
  #     tag: "myapp:v1.0"
  #   )
  #
  # @see Docker::Image.build
  # @see TagImage
  # @since 0.1.0
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

    # Build a Docker image from Dockerfile content.
    #
    # This method creates a Docker image by building from the provided Dockerfile
    # content string. The Dockerfile is processed by the Docker daemon and can
    # include any valid Dockerfile instructions. Optionally, the resulting image
    # can be tagged with a custom name for easy reference.
    #
    # @param dockerfile [String] the complete Dockerfile content as a string
    # @param server_context [Object] MCP server context (unused but required)
    # @param tag [String, nil] optional tag to apply to the built image
    #
    # @return [MCP::Tool::Response] build results including image ID and tag info
    #
    # @raise [Docker::Error] for Docker daemon communication errors
    # @raise [StandardError] for build failures or other errors
    #
    # @example Build simple image
    #   dockerfile = <<~DOCKERFILE
    #     FROM alpine:latest
    #     RUN apk add --no-cache nginx
    #     EXPOSE 80
    #     CMD ["nginx", "-g", "daemon off;"]
    #   DOCKERFILE
    #
    #   response = BuildImage.call(
    #     server_context: context,
    #     dockerfile: dockerfile,
    #     tag: "my-nginx:latest"
    #   )
    #
    # @see Docker::Image.build
    def self.call(dockerfile:, server_context:, tag: nil)
      # Build the image
      image = Docker::Image.build(dockerfile)

      # If a tag was specified, tag the image
      if tag
        # Split tag into repo and tag parts
        repo, image_tag = tag.split(':', 2)
        image_tag ||= 'latest'
        image.tag('repo' => repo, 'tag' => image_tag, 'force' => true)
      end

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
