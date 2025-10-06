# frozen_string_literal: true

RSpec.describe DockerMCP do
  it 'has a version number' do
    expect(DockerMCP::VERSION).not_to be_nil
  end
end
