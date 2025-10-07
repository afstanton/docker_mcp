# frozen_string_literal: true

module DockerMCP
  # MCP tool for pulling Docker images from registries.
  #
  # This tool provides the ability to download Docker images from Docker
  # registries (like Docker Hub) to the local system. It supports flexible
  # tag specification and handles various image naming conventions.
  #
  # == Features
  #
  # - Pull images from any accessible Docker registry
  # - Flexible tag specification (explicit or default)
  # - Support for official and user repositories
  # - Automatic latest tag handling
  # - Comprehensive error handling
  # - Progress tracking through Docker daemon
  #
  # == Security Considerations
  #
  # Pulling images can introduce security risks:
  # - **Malicious Images**: Images may contain malware or backdoors
  # - **Vulnerable Software**: Images may have known security vulnerabilities
  # - **Untrusted Sources**: Images from unknown publishers may be compromised
  # - **Supply Chain Attacks**: Legitimate-looking images may be malicious
  # - **Resource Consumption**: Large images can consume significant disk space
  #
  # Security recommendations:
  # - Only pull images from trusted registries and publishers
  # - Verify image signatures when available
  # - Scan pulled images for vulnerabilities
  # - Use specific tags rather than 'latest'
  # - Monitor registry access and authentication
  # - Regularly update and patch images
  #
  # == Tag Handling
  #
  # The tool handles tags intelligently:
  # - If image includes tag (e.g., "nginx:1.21"), use as specified
  # - If separate tag provided, append to image name
  # - If no tag specified, default to "latest"
  # - Supports all Docker tag conventions
  #
  # == Example Usage
  #
  #   # Pull latest version
  #   PullImage.call(
  #     server_context: context,
  #     from_image: "nginx"
  #   )
  #
  #   # Pull specific version
  #   PullImage.call(
  #     server_context: context,
  #     from_image: "postgres:13"
  #   )
  #
  #   # Pull with separate tag parameter
  #   PullImage.call(
  #     server_context: context,
  #     from_image: "redis",
  #     tag: "7-alpine"
  #   )
  #
  # @see BuildImage
  # @see ListImages
  # @see Docker::Image.create
  # @since 0.1.0
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

    # Pull a Docker image from a registry.
    #
    # This method downloads the specified image from a Docker registry to
    # the local system. It handles tag resolution automatically and provides
    # feedback on the pull operation status.
    #
    # @param from_image [String] image name (may include registry and tag)
    # @param server_context [Object] MCP server context (unused but required)
    # @param tag [String, nil] specific tag to pull (overrides tag in from_image)
    #
    # @return [MCP::Tool::Response] pull operation results with image ID
    #
    # @raise [Docker::Error::NotFoundError] if image doesn't exist in registry
    # @raise [StandardError] for network or authentication failures
    #
    # @example Pull official image
    #   response = PullImage.call(
    #     server_context: context,
    #     from_image: "ubuntu:22.04"
    #   )
    #
    # @example Pull from custom registry
    #   response = PullImage.call(
    #     server_context: context,
    #     from_image: "registry.example.com/myapp",
    #     tag: "v1.0"
    #   )
    #
    # @see Docker::Image.create
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
