# frozen_string_literal: true

module DockerMCP
  # MCP tool for removing Docker images.
  #
  # This tool provides the ability to delete Docker images from the
  # local Docker daemon. It supports various removal options including
  # forced removal and parent image cleanup management.
  #
  # == Features
  #
  # - Remove images by ID, name, or tag
  # - Force removal of images in use
  # - Control untagged parent image cleanup
  # - Comprehensive error handling
  # - Validation of image existence
  # - Safe removal with dependency checking
  #
  # == Security Considerations
  #
  # Image removal involves important considerations:
  # - **Data Loss**: Removed images cannot be recovered locally
  # - **Service Disruption**: Removing images used by running containers
  # - **Storage Cleanup**: Improper cleanup can leave orphaned layers
  # - **Registry Impact**: Local removal doesn't affect registry copies
  # - **Dependency Conflicts**: Force removal can break container dependencies
  #
  # **Security Recommendations**:
  # - Verify image is not in use before removal
  # - Use force option only when necessary
  # - Consider impact on running containers
  # - Backup important images before removal
  # - Monitor disk space after removal operations
  # - Implement image lifecycle policies
  #
  # == Parameters
  #
  # - **id**: Image ID, name, or name:tag (required)
  # - **force**: Force removal of the image (optional, default: false)
  # - **noprune**: Do not delete untagged parents (optional, default: false)
  #
  # == Example Usage
  #
  #   # Remove specific image
  #   response = RemoveImage.call(
  #     server_context: context,
  #     id: "myapp:old-version"
  #   )
  #
  #   # Force remove image in use
  #   response = RemoveImage.call(
  #     server_context: context,
  #     id: "abc123def456",
  #     force: true
  #   )
  #
  #   # Remove without cleaning parent images
  #   response = RemoveImage.call(
  #     server_context: context,
  #     id: "test-image:latest",
  #     noprune: true
  #   )
  #
  # @see Docker::Image#remove
  # @since 0.1.0
  REMOVE_IMAGE_DEFINITION = ToolForge.define(:remove_image) do
    description 'Remove a Docker image'

    param :id,
          type: :string,
          description: 'Image ID, name, or name:tag'

    param :force,
          type: :boolean,
          description: 'Force removal of the image (default: false)',
          required: false,
          default: false

    param :noprune,
          type: :boolean,
          description: 'Do not delete untagged parents (default: false)',
          required: false,
          default: false

    execute do |id:, force: false, noprune: false|
      image = Docker::Image.get(id)
      image.remove(force: force, noprune: noprune)

      "Image #{id} removed successfully"
    rescue Docker::Error::NotFoundError
      "Image #{id} not found"
    rescue StandardError => e
      "Error removing image: #{e.message}"
    end
  end

  RemoveImage = REMOVE_IMAGE_DEFINITION.to_mcp_tool
end
