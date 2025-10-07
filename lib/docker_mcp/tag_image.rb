# frozen_string_literal: true

module DockerMCP
  # MCP tool for tagging Docker images.
  #
  # This tool provides the ability to create new tags for existing Docker images,
  # enabling better organization, versioning, and distribution of images. Tags
  # are essential for image management and registry operations.
  #
  # == Features
  #
  # - Tag images by ID or existing name
  # - Support for repository and tag specification
  # - Force tagging to overwrite existing tags
  # - Registry-compatible tag formatting
  # - Comprehensive error handling
  # - Multiple tags per image support
  #
  # == Tag Management Benefits
  #
  # Proper tagging enables:
  # - **Version Control**: Track different image versions
  # - **Distribution**: Prepare images for registry push
  # - **Organization**: Group related images logically
  # - **Deployment**: Reference specific image versions
  # - **Rollback**: Maintain previous versions for rollback
  #
  # == Security Considerations
  #
  # Tagging affects image accessibility and distribution:
  # - Tags determine registry push destinations
  # - Overwriting tags can affect running containers
  # - Registry-compatible tags expose images for distribution
  # - Tag names may reveal application details
  #
  # Best practices:
  # - Use descriptive but not sensitive tag names
  # - Avoid overwriting production tags accidentally
  # - Implement tag naming conventions
  # - Regular cleanup of unused tags
  # - Control access to critical tag operations
  #
  # == Tag Naming Conventions
  #
  # Recommended patterns:
  # - **Semantic Versioning**: `v1.2.3`, `1.2.3-alpha`
  # - **Environment Tags**: `prod`, `staging`, `dev`
  # - **Feature Tags**: `feature-branch-name`
  # - **Date Tags**: `2024-01-15`, `20240115`
  # - **Commit Tags**: `sha-abc123def`
  #
  # == Example Usage
  #
  #   # Tag with version
  #   TagImage.call(
  #     server_context: context,
  #     id: "abc123def456",
  #     repo: "myapp",
  #     tag: "v1.0.0"
  #   )
  #
  #   # Tag for registry push
  #   TagImage.call(
  #     server_context: context,
  #     id: "myapp:latest",
  #     repo: "myusername/myapp",
  #     tag: "production"
  #   )
  #
  #   # Tag for private registry
  #   TagImage.call(
  #     server_context: context,
  #     id: "webapp:dev",
  #     repo: "registry.company.com/team/webapp",
  #     tag: "v2.1.0"
  #   )
  #
  # @see BuildImage
  # @see PushImage
  # @see Docker::Image#tag
  # @since 0.1.0
  class TagImage < MCP::Tool
    description 'Tag a Docker image'

    input_schema(
      properties: {
        id: {
          type: 'string',
          description: 'Image ID or current name:tag'
        },
        repo: {
          type: 'string',
          description: 'Repository name (e.g., "username/imagename" or "registry/username/imagename")'
        },
        tag: {
          type: 'string',
          description: 'Tag for the image (default: "latest")'
        },
        force: {
          type: 'boolean',
          description: 'Force tag even if it already exists (default: true)'
        }
      },
      required: %w[id repo]
    )

    # Tag a Docker image with a new repository and tag name.
    #
    # This method creates a new tag for an existing image, allowing it to
    # be referenced by the new name. This is essential for organizing images
    # and preparing them for registry distribution.
    #
    # @param id [String] image ID or current name:tag to tag
    # @param repo [String] repository name for the new tag
    # @param server_context [Object] MCP server context (unused but required)
    # @param tag [String] tag name for the image (default: "latest")
    # @param force [Boolean] whether to overwrite existing tags (default: true)
    #
    # @return [MCP::Tool::Response] tagging operation results
    #
    # @raise [Docker::Error::NotFoundError] if source image doesn't exist
    # @raise [StandardError] for other tagging failures
    #
    # @example Tag for versioning
    #   response = TagImage.call(
    #     server_context: context,
    #     id: "my-app:latest",
    #     repo: "my-app",
    #     tag: "v1.2.3"
    #   )
    #
    # @example Tag for registry push
    #   response = TagImage.call(
    #     server_context: context,
    #     id: "abc123def456",
    #     repo: "myregistry.com/myuser/myapp",
    #     tag: "production",
    #     force: true
    #   )
    #
    # @see Docker::Image#tag
    def self.call(id:, repo:, server_context:, tag: 'latest', force: true)
      image = Docker::Image.get(id)

      image.tag('repo' => repo, 'tag' => tag, 'force' => force)

      MCP::Tool::Response.new([{
                                type: 'text',
                                text: "Image tagged successfully as #{repo}:#{tag}"
                              }])
    rescue Docker::Error::NotFoundError
      MCP::Tool::Response.new([{
                                type: 'text',
                                text: "Image #{id} not found"
                              }])
    rescue StandardError => e
      MCP::Tool::Response.new([{
                                type: 'text',
                                text: "Error tagging image: #{e.message}"
                              }])
    end
  end
end
