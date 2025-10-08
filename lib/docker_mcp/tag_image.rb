# frozen_string_literal: true

module DockerMCP
  # MCP tool for tagging Docker images.
  #
  # This tool provides the ability to assign repository names and tags
  # to Docker images. Tagging is essential for image organization,
  # versioning, and distribution through Docker registries.
  #
  # == Features
  #
  # - Tag existing images with custom repository names
  # - Support for version and environment tags
  # - Force tagging to overwrite existing tags
  # - Registry-compatible naming conventions
  # - Automatic tag defaulting to "latest"
  # - Comprehensive error handling and validation
  #
  # == Security Considerations
  #
  # Image tagging involves several security considerations:
  # - **Registry Authentication**: Tags may trigger registry operations
  # - **Namespace Conflicts**: Overwriting tags can affect other deployments
  # - **Image Identity**: Improper tagging can lead to deployment confusion
  # - **Version Management**: Incorrect tags can compromise CI/CD pipelines
  # - **Registry Pollution**: Excessive tagging can clutter registries
  #
  # **Security Recommendations**:
  # - Use consistent naming conventions
  # - Implement tag governance policies
  # - Verify image identity before tagging
  # - Avoid overwriting production tags
  # - Use semantic versioning for releases
  # - Monitor tag usage and lifecycle
  #
  # == Parameters
  #
  # - **id**: Image ID or current name:tag to tag (required)
  # - **repo**: Repository name (required, e.g., "username/imagename" or "registry/username/imagename")
  # - **tag**: Tag for the image (optional, default: "latest")
  # - **force**: Force tag even if it already exists (optional, default: true)
  #
  # == Example Usage
  #
  #   # Tag image with version
  #   response = TagImage.call(
  #     server_context: context,
  #     id: "myapp:dev",
  #     repo: "myregistry/myapp",
  #     tag: "v1.2.3"
  #   )
  #
  #   # Tag for production deployment
  #   response = TagImage.call(
  #     server_context: context,
  #     id: "abc123def456",
  #     repo: "production/webapp",
  #     tag: "stable",
  #     force: false
  #   )
  #
  #   # Tag with registry prefix
  #   response = TagImage.call(
  #     server_context: context,
  #     id: "local-build:latest",
  #     repo: "registry.company.com/team/service",
  #     tag: "release-candidate"
  #   )
  #
  # @see Docker::Image#tag
  # @since 0.1.0
  TAG_IMAGE_DEFINITION = ToolForge.define(:tag_image) do
    description 'Tag a Docker image'

    param :id,
          type: :string,
          description: 'Image ID or current name:tag to tag'

    param :repo,
          type: :string,
          description: 'Repository name (e.g., "username/imagename" or "registry/username/imagename")'

    param :tag,
          type: :string,
          description: 'Tag for the image (default: "latest")',
          required: false,
          default: 'latest'

    param :force,
          type: :boolean,
          description: 'Force tag even if it already exists (default: true)',
          required: false,
          default: true

    execute do |id:, repo:, tag: 'latest', force: true|
      image = Docker::Image.get(id)

      image.tag('repo' => repo, 'tag' => tag, 'force' => force)

      "Image tagged successfully as #{repo}:#{tag}"
    rescue Docker::Error::NotFoundError
      "Image #{id} not found"
    rescue StandardError => e
      "Error tagging image: #{e.message}"
    end
  end

  TagImage = TAG_IMAGE_DEFINITION.to_mcp_tool
end
