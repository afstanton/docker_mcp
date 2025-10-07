# frozen_string_literal: true

module DockerMCP
  # MCP tool for removing Docker images.
  #
  # This tool provides the ability to permanently delete Docker images from
  # the local system to free up disk space and remove unused images. It
  # supports both regular and forced removal with options for parent image
  # handling.
  #
  # == Features
  #
  # - Remove images by ID, name, or name:tag
  # - Force removal of images in use
  # - Control parent image cleanup
  # - Comprehensive error handling
  # - Safe removal with dependency checking
  #
  # == ⚠️ Data Loss Warning ⚠️
  #
  # **DESTRUCTIVE OPERATION - PERMANENT DATA LOSS**
  #
  # This operation permanently deletes images and associated data:
  # - Image layers are deleted from disk
  # - All tags pointing to the image are removed
  # - Operation cannot be undone
  # - Dependent containers may become unusable
  # - Custom modifications to images are lost
  #
  # == Dependency Management
  #
  # Docker images have complex dependency relationships:
  # - **Child Images**: Images built FROM this image
  # - **Parent Images**: Base images this image depends on
  # - **Running Containers**: Containers using this image
  # - **Stopped Containers**: Containers that could be restarted
  #
  # == Security Considerations
  #
  # Image removal affects system security posture:
  # - Removes potentially vulnerable software
  # - May break running applications
  # - Could remove security patches
  # - Affects rollback capabilities
  #
  # Best practices:
  # - Verify no critical containers depend on the image
  # - Backup important images before removal
  # - Use force removal judiciously
  # - Monitor disk space after removal
  # - Maintain image inventory documentation
  #
  # == Removal Options
  #
  # - **Normal Removal**: Only removes if no containers use the image
  # - **Force Removal**: Removes even if containers depend on it
  # - **Prune Parents**: Automatically removes unused parent images
  # - **No Prune**: Keeps parent images even if unused
  #
  # == Example Usage
  #
  #   # Safe removal of unused image
  #   RemoveImage.call(
  #     server_context: context,
  #     id: "old-app:v1.0"
  #   )
  #
  #   # Force removal of image in use
  #   RemoveImage.call(
  #     server_context: context,
  #     id: "broken-image:latest",
  #     force: true
  #   )
  #
  #   # Remove image but keep parent layers
  #   RemoveImage.call(
  #     server_context: context,
  #     id: "temp-build:abc123",
  #     noprune: true
  #   )
  #
  # @see ListImages
  # @see BuildImage
  # @see Docker::Image#remove
  # @since 0.1.0
  class RemoveImage < MCP::Tool
    description 'Remove a Docker image'

    input_schema(
      properties: {
        id: {
          type: 'string',
          description: 'Image ID, name, or name:tag'
        },
        force: {
          type: 'boolean',
          description: 'Force removal of the image (default: false)'
        },
        noprune: {
          type: 'boolean',
          description: 'Do not delete untagged parents (default: false)'
        }
      },
      required: ['id']
    )

    # Remove a Docker image from the local system.
    #
    # This method permanently deletes the specified image from local storage.
    # By default, it performs safety checks to prevent removal of images with
    # dependent containers. Force removal bypasses these checks.
    #
    # @param id [String] image ID, name, or name:tag to remove
    # @param server_context [Object] MCP server context (unused but required)
    # @param force [Boolean] whether to force removal despite dependencies (default: false)
    # @param noprune [Boolean] whether to preserve parent images (default: false)
    #
    # @return [MCP::Tool::Response] removal operation results
    #
    # @raise [Docker::Error::NotFoundError] if image doesn't exist
    # @raise [StandardError] for removal failures or dependency conflicts
    #
    # @example Remove unused image
    #   response = RemoveImage.call(
    #     server_context: context,
    #     id: "old-version:1.0"
    #   )
    #
    # @example Force remove problematic image
    #   response = RemoveImage.call(
    #     server_context: context,
    #     id: "corrupted-image",
    #     force: true
    #   )
    #
    # @example Remove while preserving layers
    #   response = RemoveImage.call(
    #     server_context: context,
    #     id: "temp-image:build-123",
    #     noprune: true
    #   )
    #
    # @see Docker::Image#remove
    def self.call(id:, server_context:, force: false, noprune: false)
      image = Docker::Image.get(id)
      image.remove(force: force, noprune: noprune)

      MCP::Tool::Response.new([{
                                type: 'text',
                                text: "Image #{id} removed successfully"
                              }])
    rescue Docker::Error::NotFoundError
      MCP::Tool::Response.new([{
                                type: 'text',
                                text: "Image #{id} not found"
                              }])
    rescue StandardError => e
      MCP::Tool::Response.new([{
                                type: 'text',
                                text: "Error removing image: #{e.message}"
                              }])
    end
  end
end
