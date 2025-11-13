# frozen_string_literal: true

# Shared examples for testing generator template file operations
RSpec.shared_examples 'a generator that creates template files' do |template_mappings|
  template_mappings.each do |source, destination|
    it "creates #{destination} from #{source}" do
      expect(generator).to have_received(:template).with(source, destination)
    end
  end
end

# Shared examples for testing generator directory operations
RSpec.shared_examples 'a generator that creates directories' do |directory_mappings|
  directory_mappings.each do |source, destination|
    it "creates #{destination} directory from #{source}" do
      expect(generator).to have_received(:directory).with(source, destination)
    end
  end
end

# Shared examples for testing generator shell command execution
RSpec.shared_examples 'a generator that runs shell commands' do |commands|
  commands.each do |command|
    it "runs #{command}" do
      expect(generator).to have_received(:run).with(command)
    end
  end
end
