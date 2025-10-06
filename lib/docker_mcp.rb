# frozen_string_literal: true

require 'docker'
require 'mcp'
require 'zeitwerk'

loader = Zeitwerk::Loader.for_gem(warn_on_extra_files: false)
loader.inflector.inflect('docker_mcp' => 'DockerMCP')
loader.setup # ready!

require_relative 'docker_mcp/version'

module DockerMCP
  class Error < StandardError; end
  # Your code goes here...
end
