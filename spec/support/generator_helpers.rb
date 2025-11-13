# frozen_string_literal: true

require 'securerandom'
require 'fileutils'

# Shared helpers for generator tests
module GeneratorHelpers
  # Creates a temporary directory for testing file operations
  def create_temp_directory(base_path)
    temp_dir = File.join(base_path, SecureRandom.hex(8))
    FileUtils.mkdir_p(temp_dir)
    temp_dir
  end

  # Cleans up temporary directory after test
  def cleanup_temp_directory(path)
    FileUtils.rm_rf(path) if Dir.exist?(path)
  end

  # Creates a mock Rails application structure
  def create_mock_rails_structure(base_path)
    FileUtils.mkdir_p(File.join(base_path, 'app', 'controllers'))
    FileUtils.mkdir_p(File.join(base_path, 'app', 'views'))
    FileUtils.mkdir_p(File.join(base_path, 'app', 'models'))
    FileUtils.mkdir_p(File.join(base_path, 'config'))
    FileUtils.touch(File.join(base_path, 'Gemfile'))
    FileUtils.touch(File.join(base_path, 'config', 'routes.rb'))
    File.write(File.join(base_path, 'config', 'routes.rb'), "Rails.application.routes.draw do\nend\n")
  end
end

RSpec.configure do |config|
  config.include GeneratorHelpers
end
