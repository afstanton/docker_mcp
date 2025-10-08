# frozen_string_literal: true

module DockerMCP
  # MCP tool for listing Docker images.
  #
  # This tool provides comprehensive information about all Docker images
  # stored on the local system. It returns detailed metadata including
  # image sizes, creation dates, tags, and usage statistics.
  #
  # == Features
  #
  # - Lists all locally stored Docker images
  # - Provides detailed image metadata and statistics
  # - Shows image sizes and storage usage
  # - Displays repository tags and digests
  # - Includes creation timestamps and labels
  # - Reports container usage counts
  #
  # == Security Considerations
  #
  # This tool provides information that could be useful for:
  # - **System Analysis**: Reveals installed software and versions
  # - **Vulnerability Assessment**: Shows potential attack surfaces
  # - **Resource Planning**: Exposes storage usage patterns
  #
  # Monitor access to this tool in production environments.
  #
  # == Return Format
  #
  # Returns an array of image objects with comprehensive metadata:
  # - Repository tags and digests
  # - Image sizes and virtual sizes
  # - Creation timestamps
  # - Container usage counts
  # - Labels and annotations
  # - Parent-child relationships
  #
  # == Example Usage
  #
  #   images = ListImages.call(server_context: context)
  #   images.each do |image|
  #     puts "#{image['RepoTags']}: #{image['Size']} bytes"
  #   end
  #
  # @see Docker::Image.all
  # @since 0.1.0
  LIST_IMAGES_DEFINITION = ToolForge.define(:list_images) do
    description 'List Docker images'

    execute do
      Docker::Image.all.map(&:info)
    end
  end

  ListImages = LIST_IMAGES_DEFINITION.to_mcp_tool
end
