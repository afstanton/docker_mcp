# frozen_string_literal: true

require 'json'
require 'open3'

module DockerMCP
  # MCP tool for pushing Docker images to registries.
  #
  # This tool provides the ability to upload Docker images to Docker registries
  # such as Docker Hub, private registries, or cloud-based container registries.
  # It uses the Docker CLI to leverage native credential handling and push
  # capabilities.
  #
  # == Features
  #
  # - Push images to any accessible Docker registry
  # - Flexible image and tag specification
  # - Native Docker credential handling
  # - Support for private registries
  # - Comprehensive error handling
  # - Validation of registry-compatible names
  #
  # == ⚠️ Security Considerations ⚠️
  #
  # Pushing images involves significant security risks:
  # - **Credential Exposure**: Registry credentials may be exposed
  # - **Data Exfiltration**: Images may contain sensitive application data
  # - **Intellectual Property**: Source code and binaries may be exposed
  # - **Supply Chain Risk**: Malicious actors could access pushed images
  # - **Registry Access**: Unauthorized access to registry accounts
  #
  # Critical security measures:
  # - Verify registry authentication and authorization
  # - Scan images for secrets before pushing
  # - Use private registries for sensitive applications
  # - Implement image signing and verification
  # - Monitor registry access and downloads
  # - Regularly audit pushed image contents
  #
  # == Registry Requirements
  #
  # Images must be properly tagged for registry compatibility:
  # - Include registry hostname for private registries
  # - Include username/organization for Docker Hub
  # - Examples: `username/myapp`, `registry.company.com/team/app`
  # - Local image names (without `/`) cannot be pushed
  #
  # == Example Usage
  #
  #   # Push to Docker Hub
  #   PushImage.call(
  #     server_context: context,
  #     name: "myusername/myapp",
  #     tag: "v1.0"
  #   )
  #
  #   # Push to private registry
  #   PushImage.call(
  #     server_context: context,
  #     name: "registry.company.com/team/app",
  #     tag: "latest"
  #   )
  #
  #   # Push with full repo specification
  #   PushImage.call(
  #     server_context: context,
  #     name: "myapp",
  #     repo_tag: "myregistry.com/myuser/myapp:v2.0"
  #   )
  #
  # @see PullImage
  # @see TagImage
  # @see BuildImage
  # @since 0.1.0
  class PushImage < MCP::Tool
    description 'Push a Docker image'

    input_schema(
      properties: {
        name: {
          type: 'string',
          description: 'Image name or ID to push'
        },
        tag: {
          type: 'string',
          description: 'Tag to push (optional, pushes all tags if not specified)'
        },
        repo_tag: {
          type: 'string',
          description: 'Full repo:tag to push (e.g., "registry/repo:tag") (optional)'
        }
      },
      required: ['name']
    )

    # Push a Docker image to a registry.
    #
    # This method uploads the specified image to a Docker registry using
    # the Docker CLI for native credential handling. The image must be
    # properly tagged for registry compatibility.
    #
    # @param name [String] image name or ID to push
    # @param server_context [Object] MCP server context (unused but required)
    # @param tag [String, nil] specific tag to push
    # @param repo_tag [String, nil] complete repository:tag specification
    #
    # @return [MCP::Tool::Response] push operation results
    #
    # @raise [StandardError] for push failures or authentication issues
    #
    # @example Push tagged image to Docker Hub
    #   response = PushImage.call(
    #     server_context: context,
    #     name: "myuser/webapp",
    #     tag: "v1.2.3"
    #   )
    #
    # @example Push to private registry
    #   response = PushImage.call(
    #     server_context: context,
    #     name: "internal-registry.com/team/service",
    #     tag: "latest"
    #   )
    #
    # @see Docker::Image.get
    def self.call(name:, server_context:, tag: nil, repo_tag: nil)
      # Construct the full image identifier
      image_identifier = tag ? "#{name}:#{tag}" : name

      # Validate that the image name includes a registry/username
      # Images without a registry prefix will fail to push to Docker Hub
      unless name.include?('/') || repo_tag&.include?('/')
        error_msg = 'Error: Image name must include registry/username ' \
                    "(e.g., 'username/#{name}'). Local images cannot be " \
                    'pushed without a registry prefix.'
        return MCP::Tool::Response.new([{
                                         type: 'text',
                                         text: error_msg
                                       }])
      end

      # Verify the image exists
      begin
        Docker::Image.get(image_identifier)
      rescue Docker::Error::NotFoundError
        return MCP::Tool::Response.new([{
                                         type: 'text',
                                         text: "Image #{image_identifier} not found"
                                       }])
      end

      # Use the Docker CLI to push the image
      # This way we leverage Docker's native credential handling
      push_target = repo_tag || image_identifier
      _, stderr, status = Open3.capture3('docker', 'push', push_target)

      if status.success?
        MCP::Tool::Response.new([{
                                  type: 'text',
                                  text: "Image #{push_target} pushed successfully"
                                }])
      else
        # Extract the error message from stderr
        error_msg = stderr.strip
        error_msg = 'Failed to push image' if error_msg.empty?

        MCP::Tool::Response.new([{
                                  type: 'text',
                                  text: "Error pushing image: #{error_msg}"
                                }])
      end
    rescue StandardError => e
      MCP::Tool::Response.new([{
                                type: 'text',
                                text: "Error pushing image: #{e.message}"
                              }])
    end
  end
end
