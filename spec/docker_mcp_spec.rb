# frozen_string_literal: true

RSpec.describe DockerMcp do
  it 'has a version number' do
    expect(DockerMcp::VERSION).not_to be_nil
  end
end
