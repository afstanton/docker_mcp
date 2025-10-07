# frozen_string_literal: true

require 'docker'
require 'json'
require 'mcp'
require 'rubygems/package'
require 'shellwords'
require 'stringio'
require 'zeitwerk'

loader = Zeitwerk::Loader.for_gem(warn_on_extra_files: false)
loader.inflector.inflect('docker_mcp' => 'DockerMCP')
loader.setup # ready!

require_relative 'docker_mcp/version'

# DockerMCP provides a Model Context Protocol (MCP) server for comprehensive Docker management.
#
# This module serves as the main namespace for all Docker MCP functionality, providing tools
# to interact with Docker containers, images, networks, and volumes through a standardized
# MCP interface. It enables AI assistants and other MCP clients to perform Docker operations
# programmatically.
#
# == Security Warning
#
# This tool provides powerful capabilities that can be potentially dangerous:
# - Execute arbitrary commands inside containers
# - Access and modify container filesystems
# - Create, modify, and delete Docker resources
#
# Use with caution and ensure proper security measures are in place.
#
# == Example Usage
#
#   # Initialize the MCP server
#   server = DockerMCP::Server.new
#
#   # The server provides access to 22 Docker management tools:
#   # - Container management (create, run, start, stop, remove, etc.)
#   # - Image management (pull, build, tag, push, remove)
#   # - Network management (create, list, remove)
#   # - Volume management (create, list, remove)
#
# == Dependencies
#
# Requires:
# - Docker Engine installed and running
# - Ruby 3.2+
# - docker-api gem for Docker interactions
# - mcp gem for Model Context Protocol support
#
# @see https://github.com/afstanton/docker_mcp
# @since 0.1.0
module DockerMCP
  # Base error class for all DockerMCP-specific errors.
  #
  # This error class serves as the parent for any custom exceptions
  # that may be raised by DockerMCP operations. It inherits from
  # StandardError to maintain compatibility with standard Ruby
  # error handling patterns.
  #
  # @example Rescue DockerMCP errors
  #   begin
  #     # DockerMCP operations
  #   rescue DockerMCP::Error => e
  #     puts "DockerMCP error: #{e.message}"
  #   end
  class Error < StandardError; end
end
