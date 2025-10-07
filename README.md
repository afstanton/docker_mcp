# DockerMCP

A Model Context Protocol (MCP) server that provides comprehensive Docker management capabilities through a standardized interface. This tool enables AI assistants and other MCP clients to interact with Docker containers, images, networks, and volumes programmatically.

## ⚠️ Security Warning

**This tool is inherently unsafe and should be used with extreme caution.**

- **Arbitrary Code Execution**: The `exec_container` tool allows execution of arbitrary commands inside Docker containers
- **File System Access**: The `copy_to_container` tool can copy files from the host system into containers
- **Container Management**: Full container lifecycle management including creation, modification, and deletion
- **Network & Volume Control**: Complete control over Docker networks and volumes

**Recommendations:**
- Only use in trusted environments
- Ensure proper Docker daemon security configuration
- Consider running with restricted Docker permissions
- Monitor and audit all container operations
- Be cautious when exposing this tool to external or untrusted MCP clients

## Installation

Install the gem and add to the application's Gemfile by executing:

```bash
bundle add docker_mcp
```

If bundler is not being used to manage dependencies, install the gem by executing:

```bash
gem install docker_mcp
```

## Prerequisites

- Docker Engine installed and running
- Ruby 3.2+
- Docker permissions for the user running the MCP server

## Usage

### MCP Client Configuration

Add this to your MCP client configuration after installing the gem:

```json
{
  "docker_mcp": {
    "command": "bash",
    "args": [
      "-l",
      "-c",
      "docker_mcp"
    ]
  }
}
```

### Example Usage

Once configured, you can use the tools through your MCP client:

```
# List all containers
list_containers

# Create and run a new container
run_container image="nginx:latest" name="my-web-server"

# Execute commands in a container
exec_container id="my-web-server" cmd="nginx -v"

# Copy files to a container
copy_to_container id="my-web-server" source_path="/local/file.txt" destination_path="/var/www/html/"

# View container logs
fetch_container_logs id="my-web-server"
```

## 🔨 Tools

This MCP server provides 22 comprehensive Docker management tools organized by functionality:

### Container Management

- **`list_containers`** - List all Docker containers (running and stopped) with detailed information
- **`create_container`** - Create a new container from an image without starting it
- **`run_container`** - Create and immediately start a container from an image
- **`start_container`** - Start an existing stopped container
- **`stop_container`** - Stop a running container gracefully
- **`remove_container`** - Delete a container (must be stopped first unless forced)
- **`recreate_container`** - Stop, remove, and recreate a container with the same configuration
- **`exec_container`** ⚠️ - Execute arbitrary commands inside a running container
- **`fetch_container_logs`** - Retrieve stdout/stderr logs from a container
- **`copy_to_container`** ⚠️ - Copy files or directories from host to container

### Image Management

- **`list_images`** - List all Docker images available locally
- **`pull_image`** - Download an image from a Docker registry
- **`push_image`** - Upload an image to a Docker registry
- **`build_image`** - Build a new image from a Dockerfile
- **`tag_image`** - Create a new tag for an existing image
- **`remove_image`** - Delete an image from local storage

### Network Management

- **`list_networks`** - List all Docker networks
- **`create_network`** - Create a new Docker network
- **`remove_network`** - Delete a Docker network

### Volume Management

- **`list_volumes`** - List all Docker volumes
- **`create_volume`** - Create a new Docker volume for persistent data
- **`remove_volume`** - Delete a Docker volume

### Tool Parameters

Most tools accept standard Docker parameters:
- **Container ID/Name**: Can use either the full container ID, short ID, or container name
- **Image**: Specify images using `name:tag` format (e.g., `nginx:latest`, `ubuntu:22.04`)
- **Ports**: Use Docker port mapping syntax (e.g., `"8080:80"`)
- **Volumes**: Use Docker volume mount syntax (e.g., `"/host/path:/container/path"`)
- **Environment**: Set environment variables as `KEY=VALUE` pairs

## Common Use Cases

### Development Environment Setup
```bash
# Pull development image
pull_image from_image="node:18-alpine"

# Create development container with volume mounts
run_container image="node:18-alpine" name="dev-env" \
  host_config='{"PortBindings":{"3000/tcp":[{"HostPort":"3000"}]},"Binds":["/local/project:/app"]}'

# Execute development commands
exec_container id="dev-env" cmd="npm install"
exec_container id="dev-env" cmd="npm start"
```

### Container Debugging
```bash
# Check container status
list_containers

# View container logs
fetch_container_logs id="problematic-container"

# Execute diagnostic commands
exec_container id="problematic-container" cmd="ps aux"
exec_container id="problematic-container" cmd="df -h"
exec_container id="problematic-container" cmd="netstat -tlnp"
```

### File Management
```bash
# Copy configuration files to container
copy_to_container id="web-server" \
  source_path="/local/nginx.conf" \
  destination_path="/etc/nginx/"

# Copy application code
copy_to_container id="app-container" \
  source_path="/local/src" \
  destination_path="/app/"
```

## Error Handling

The server provides detailed error messages for common issues:

- **Container Not Found**: When referencing non-existent containers
- **Image Not Available**: When trying to use images that aren't pulled locally
- **Permission Denied**: When Docker daemon access is restricted
- **Network Conflicts**: When creating networks with conflicting configurations
- **Volume Mount Issues**: When specified paths don't exist or lack permissions

All errors include descriptive messages to help diagnose and resolve issues.

## Troubleshooting

### Docker Daemon Connection Issues
```bash
# Check if Docker daemon is running
docker info

# Verify Docker permissions
docker ps

# Check MCP server logs for connection errors
```

### Container Operation Failures
- Ensure container IDs/names are correct (use `list_containers` to verify)
- Check if containers are in the expected state (running/stopped)
- Verify image availability with `list_images`

### Permission Issues
- Ensure the user running the MCP server has Docker permissions
- Consider adding user to the `docker` group: `sudo usermod -aG docker $USER`
- Verify Docker socket permissions: `ls -la /var/run/docker.sock`

## Limitations

- **Platform Specific**: Some container operations may behave differently across operating systems
- **Docker API Version**: Requires compatible Docker Engine API version
- **Resource Limits**: Large file copies and image operations may timeout
- **Concurrent Operations**: Heavy concurrent usage may impact performance

## Contributing

We welcome contributions! Areas for improvement:

- **Enhanced Security**: Additional safety checks and permission validation
- **Better Error Handling**: More specific error messages and recovery suggestions
- **Performance Optimization**: Streaming for large file operations
- **Extended Functionality**: Support for Docker Compose, Swarm, etc.
- **Testing**: Comprehensive test coverage for all tools

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

### Running Tests
```bash
# Install dependencies
bundle install

# Run the test suite
bundle exec rake spec

# Run tests with coverage
bundle exec rake spec COVERAGE=true
```

### Local Development Setup
```bash
# Clone the repository
git clone https://github.com/afstanton/docker_mcp.git
cd docker_mcp

# Install dependencies
bin/setup

# Start development console
bin/console

# Build the gem locally
bundle exec rake build

# Install locally built gem
bundle exec rake install
```

### Testing with MCP Client
```bash
# Start the MCP server locally
bundle exec exe/docker_mcp

# Configure your MCP client to use local development server
# Use file path instead of installed gem command
```

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
