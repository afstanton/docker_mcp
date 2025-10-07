# frozen_string_literal: true

module DockerMCP
  # MCP tool for listing Docker images.
  #
  # This tool provides functionality to list all Docker images available on
  # the local system. It returns comprehensive information about each image
  # including IDs, tags, sizes, creation dates, and other metadata.
  #
  # == Features
  #
  # - List all local Docker images
  # - Comprehensive image metadata
  # - No configuration required
  # - Read-only operation
  # - Includes both tagged and untagged images
  #
  # == Image Information Included
  #
  # The response typically includes:
  # - **Image ID**: Unique identifier for the image
  # - **Repository Tags**: All tags associated with the image
  # - **Size**: Virtual and actual size of the image
  # - **Created**: Timestamp when image was created
  # - **Parent ID**: Base image information
  # - **RepoDigests**: Content-addressable identifiers
  #
  # == Security Considerations
  #
  # This is a read-only operation that reveals system information:
  # - Exposes available images and versions
  # - May reveal internal application details
  # - Shows image sources and repositories
  # - Could aid in reconnaissance activities
  #
  # While generally safe, consider access control:
  # - Limit exposure of image inventory
  # - Be cautious with sensitive image names
  # - Monitor for unauthorized image access attempts
  #
  # == Example Usage
  #
  #   # List all images
  #   ListImages.call(server_context: context)
  #
  # @example Usage in container management
  #   # Get available images before container creation
  #   images_response = ListImages.call(server_context: context)
  #   # Use image information to select appropriate base images
  #
  # @see PullImage
  # @see BuildImage
  # @see Docker::Image.all
  # @since 0.1.0
  class ListImages < MCP::Tool
    description 'List Docker images'

    # List all Docker images available on the local system.
    #
    # This method retrieves information about all Docker images stored
    # locally, including both tagged and untagged images. The information
    # includes comprehensive metadata for each image.
    #
    # @param args [Array] variable arguments (unused but accepted for compatibility)
    #
    # @return [MCP::Tool::Response] comprehensive image information
    #
    # @example List all local images
    #   response = ListImages.call
    #   # Returns detailed info for all local Docker images
    #
    # @see Docker::Image.all
    def self.call(*)
      MCP::Tool::Response.new([{
                                type: 'text',
                                text: Docker::Image.all.map(&:info).to_s
                              }])
    end
  end
end
