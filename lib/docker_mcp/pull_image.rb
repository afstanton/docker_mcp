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
  # **Security Recommendations**:
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
  # == Parameters
  #
  # - **from_image**: Image name to pull (required, e.g., "ubuntu" or "ubuntu:22.04")
  # - **tag**: Tag to pull (optional, defaults to "latest" if not specified in from_image)
  #
  # == Example Usage
  #
  #   # Pull latest version
  #   response = PullImage.call(
  #     server_context: context,
  #     from_image: "nginx"
  #   )
  #
  #   # Pull specific version
  #   response = PullImage.call(
  #     server_context: context,
  #     from_image: "postgres",
  #     tag: "13.8"
  #   )
  #
  # @see Docker::Image.create
  # @since 0.1.0
  PULL_IMAGE_DEFINITION = ToolForge.define(:pull_image) do
    description 'Pull a Docker image'

    param :from_image,
          type: :string,
          description: 'Image name to pull (e.g., "ubuntu" or "ubuntu:22.04")'

    param :tag,
          type: :string,
          description: 'Tag to pull (optional, defaults to "latest" if not specified in from_image)',
          required: false

    execute do |from_image:, tag: nil|
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

      "Image #{image_with_tag} pulled successfully. ID: #{image.id}"
    rescue Docker::Error::NotFoundError
      "Image #{image_with_tag} not found"
    rescue StandardError => e
      "Error pulling image: #{e.message}"
    end
  end

  PullImage = PULL_IMAGE_DEFINITION.to_mcp_tool
end
