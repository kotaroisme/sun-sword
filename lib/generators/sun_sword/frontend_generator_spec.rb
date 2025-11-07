# frozen_string_literal: true

require 'fileutils'
require 'generators/sun_sword/frontend_generator'

RSpec.describe SunSword::FrontendGenerator, type: :generator do
  include FileUtils

  let(:destination_root) { File.expand_path('../tmp', __dir__) }

  before do
    FileUtils.mkdir_p(destination_root) unless Dir.exist?(destination_root)
  end

  after do
    FileUtils.rm_rf(destination_root) if Dir.exist?(destination_root)
  end

  describe 'generator options' do
    it 'requires the setup option' do
      generator = described_class.new([], setup: false)
      expect {
        generator.validate_setup_option
      }.to raise_error(Thor::Error, 'The --setup option must be specified to create the domain structure.')
    end

    it 'accepts the setup option' do
      generator = described_class.new([], setup: true)
      expect {
        generator.validate_setup_option
      }.not_to raise_error
    end
  end

  describe 'source root' do
    it 'has the correct source root' do
      source_path = File.expand_path('templates_frontend', File.dirname(__FILE__))
      expect(described_class.source_root).to eq(source_path)
    end
  end

  describe '#validate_setup_option' do
    context 'when setup option is false' do
      it 'raises an error' do
        generator = described_class.new([], setup: false)
        expect { generator.validate_setup_option }.to raise_error(Thor::Error)
      end
    end

    context 'when setup option is true' do
      it 'does not raise an error' do
        generator = described_class.new([], setup: true)
        expect { generator.validate_setup_option }.not_to raise_error
      end
    end
  end

  describe '#path_app' do
    it 'returns app' do
      generator = described_class.new([], setup: true)
      expect(generator.send(:path_app)).to eq('app')
    end
  end

  describe 'file operations' do
    before do
      # Create mock files and directories for testing
      FileUtils.mkdir_p(File.join(destination_root, 'app', 'assets', 'config'))
      FileUtils.mkdir_p(File.join(destination_root, 'app', 'javascript'))
      FileUtils.mkdir_p(File.join(destination_root, 'config'))
      FileUtils.touch(File.join(destination_root, 'Gemfile'))
      FileUtils.touch(File.join(destination_root, 'app', 'javascript', 'application.js'))
      FileUtils.touch(File.join(destination_root, 'config', 'routes.rb'))
    end

    it 'copies assets from template' do
      generator = described_class.new([], setup: true)
      generator.destination_root = destination_root

      allow(generator).to receive(:template)

      generator.send(:copy_assets_from_template)

      expect(generator).to have_received(:template).with(
                             'assets/config/manifest.js',
                             File.join('assets/config/manifest.js')
      )
    end

    it 'adds gem dependencies to Gemfile' do
      generator = described_class.new([], setup: true)
      generator.destination_root = destination_root

      allow(generator).to receive(:append_to_file)
      allow(generator).to receive(:say)

      generator.send(:add_vite_to_gemfile)

      expect(generator).to have_received(:append_to_file).with('Gemfile', /gem "turbo-rails"/)
    end
  end

  describe 'integration test' do
    it 'can be instantiated with setup option' do
      generator = described_class.new([], setup: true)
      expect(generator).to be_a(described_class)
      expect(generator.options[:setup]).to be true
    end
  end
end
