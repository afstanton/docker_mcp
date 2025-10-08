# frozen_string_literal: true

module DockerMCP
  # MCP tool for pushing Docker images to registries.
  #
  # This tool provides the ability to upload Docker images to Docker
  # registries such as Docker Hub, private registries, or cloud-based
  # container registries. It supports various push configurations and
  # authentication scenarios.
  #
  # == Features
  #
  # - Push images to any Docker registry
  # - Support for tagged and untagged pushes
  # - Registry authentication integration
  # - Comprehensive error handling and validation
  # - Multi-registry support
  # - Progress tracking and status reporting
  # - Registry namespace validation
  #
  # == Security Considerations
  #
  # Pushing images involves significant security risks:
  # - **Credential Exposure**: Registry credentials may be exposed
  # - **Image Integrity**: Pushed images become publicly accessible
  # - **Supply Chain Risk**: Malicious images can be distributed
  # - **Registry Security**: Vulnerable registries can be compromised
  # - **Network Exposure**: Push operations traverse networks
  # - **Access Control**: Improper permissions can lead to unauthorized access
  #
  # **Security Recommendations**:
  # - Use secure registry authentication
  # - Scan images for vulnerabilities before pushing
  # - Implement image signing and verification
  # - Use private registries for sensitive images
  # - Monitor registry access and usage
  # - Implement proper RBAC for registry operations
  # - Validate image content before distribution
  #
  # == Parameters
  #
  # - **name**: Image name or ID to push (required)
  # - **tag**: Tag to push (optional, pushes all tags if not specified)
  # - **repo_tag**: Full repo:tag to push (optional, e.g., "registry/repo:tag")
  #
  # == Example Usage
  #
  #   # Push to Docker Hub
  #   response = PushImage.call(
  #     server_context: context,
  #     name: "username/myapp",
  #     tag: "v1.0.0"
  #   )
  #
  #   # Push to private registry
  #   response = PushImage.call(
  #     server_context: context,
  #     name: "myapp",
  #     repo_tag: "registry.company.com/team/myapp:latest"
  #   )
  #
  #   # Push all tags
  #   response = PushImage.call(
  #     server_context: context,
  #     name: "username/myapp"
  #   )
  #
  # @see Docker CLI push command
  # @since 0.1.0
  PUSH_IMAGE_DEFINITION = ToolForge.define(:push_image) do
    description 'Push a Docker image'

    param :name,
          type: :string,
          description: 'Image name or ID to push'

    param :tag,
          type: :string,
          description: 'Tag to push (optional, pushes all tags if not specified)',
          required: false

    param :repo_tag,
          type: :string,
          description: 'Full repo:tag to push (e.g., "registry/repo:tag") (optional)',
          required: false

    execute do |name:, tag: nil, repo_tag: nil|
      # Construct the full image identifier
      image_identifier = tag ? "#{name}:#{tag}" : name

      # Validate that the image name includes a registry/username
      unless name.include?('/') || repo_tag&.include?('/')
        next 'Error: Image name must include registry/username ' \
             "(e.g., 'username/#{name}'). Local images cannot be " \
             'pushed without a registry prefix.'
      end

      # Verify the image exists
      begin
        Docker::Image.get(image_identifier)
      rescue Docker::Error::NotFoundError
        next "Image #{image_identifier} not found"
      end

      # Use the Docker CLI to push the image
      push_target = repo_tag || image_identifier
      _, stderr, status = Open3.capture3('docker', 'push', push_target)

      if status.success?
        "Image #{push_target} pushed successfully"
      else
        error_msg = stderr.strip
        error_msg = 'Failed to push image' if error_msg.empty?
        "Error pushing image: #{error_msg}"
      end
    rescue StandardError => e
      "Error pushing image: #{e.message}"
    end
  end

  PushImage = PUSH_IMAGE_DEFINITION.to_mcp_tool
end
