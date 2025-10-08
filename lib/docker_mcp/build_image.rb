# frozen_string_literal: true

module DockerMCP
  # MCP tool for building Docker images.
  #
  # This tool provides the ability to build Docker images from Dockerfile
  # content. It creates custom images by executing Dockerfile instructions
  # and supports comprehensive build configuration including tagging and
  # build arguments.
  #
  # == Features
  #
  # - Build images from Dockerfile content strings
  # - Support for custom image tagging
  # - Comprehensive build output and error reporting
  # - Handles all standard Dockerfile instructions
  # - Build context management
  # - Progress tracking and logging
  #
  # == Security Considerations
  #
  # Image building involves significant security risks:
  # - **Code Execution**: Dockerfile RUN commands execute arbitrary code
  # - **Network Access**: Build process can access networks and repositories
  # - **File System Access**: Can read local files and directories
  # - **Credential Exposure**: May expose build-time secrets and credentials
  # - **Supply Chain Risk**: Downloaded packages may contain malware
  # - **Resource Consumption**: Builds can consume significant CPU, memory, and storage
  #
  # **Security Recommendations**:
  # - Review all Dockerfile content before building
  # - Use trusted base images only
  # - Avoid embedding secrets in image layers
  # - Implement build isolation and sandboxing
  # - Monitor build resource consumption
  # - Scan built images for vulnerabilities
  # - Use multi-stage builds to minimize attack surface
  #
  # == Parameters
  #
  # - **dockerfile**: Dockerfile content as a string (required)
  # - **tag**: Tag for the built image (optional, e.g., "myimage:latest")
  #
  # == Example Usage
  #
  #   # Build simple image
  #   dockerfile_content = <<~DOCKERFILE
  #     FROM alpine:latest
  #     RUN apk add --no-cache curl
  #     CMD ["curl", "--version"]
  #   DOCKERFILE
  #
  #   response = BuildImage.call(
  #     server_context: context,
  #     dockerfile: dockerfile_content,
  #     tag: "my-curl:latest"
  #   )
  #
  #   # Build web server image
  #   dockerfile_content = <<~DOCKERFILE
  #     FROM nginx:alpine
  #     COPY nginx.conf /etc/nginx/nginx.conf
  #     EXPOSE 80
  #     CMD ["nginx", "-g", "daemon off;"]
  #   DOCKERFILE
  #
  #   response = BuildImage.call(
  #     server_context: context,
  #     dockerfile: dockerfile_content,
  #     tag: "custom-nginx:v1.0"
  #   )
  #
  # @see Docker::Image.build_from_dir
  # @since 0.1.0
  BUILD_IMAGE_DEFINITION = ToolForge.define(:build_image) do
    description 'Build a Docker image'

    param :dockerfile,
          type: :string,
          description: 'Dockerfile content as a string'

    param :tag,
          type: :string,
          description: 'Tag for the built image (e.g., "myimage:latest")',
          required: false

    execute do |dockerfile:, tag: nil|
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
      response_text
    rescue StandardError => e
      "Error building image: #{e.message}"
    end
  end

  BuildImage = BUILD_IMAGE_DEFINITION.to_mcp_tool
end
