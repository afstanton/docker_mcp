# frozen_string_literal: true

module DockerMCP
  LIST_CONTAINERS_DEFINITION = ToolForge.define(:list_containers) do
    description 'List Docker containers'

    param :all,
          type: :boolean,
          description: 'Show all containers (default shows all containers including stopped ones)',
          required: false,
          default: true

    execute do |all: true|
      Docker::Container.all(all: all).map(&:info)
    end
  end

  ListContainers = LIST_CONTAINERS_DEFINITION.to_mcp_tool
end
