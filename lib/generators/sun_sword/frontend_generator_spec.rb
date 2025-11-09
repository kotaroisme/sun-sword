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

      generator.send(:add_to_gemfile)
    end
  end

  describe 'integration test' do
    it 'can be instantiated with setup option' do
      generator = described_class.new([], setup: true)
      expect(generator).to be_a(described_class)
      expect(generator.options[:setup]).to be true
    end
  end

  describe 'engine support' do
    describe '#engine_path' do
      it 'returns nil when no engine option is set' do
        generator = described_class.new([], setup: true)
        expect(generator.send(:engine_path)).to be_nil
      end

      it 'returns engine path when engine option is set and exists' do
        generator = described_class.new([], setup: true, engine: 'test_engine')

        # Mock engine detection
        allow(generator).to receive(:detect_engine_path).and_return('engines/test_engine')

        expect(generator.send(:engine_path)).to eq('engines/test_engine')
      end
    end

    describe '#detect_engine_path' do
      let(:generator) { described_class.new([], setup: true, engine: 'admin') }

      it 'detects engine in engines/ directory' do
        allow(Dir).to receive(:exist?).and_call_original
        allow(Dir).to receive(:exist?).with('engines/admin').and_return(true)
        allow(File).to receive(:exist?).and_call_original
        allow(File).to receive(:exist?).with('engines/admin/admin.gemspec').and_return(true)

        expect(generator.send(:detect_engine_path)).to eq('engines/admin')
      end

      it 'detects engine in components/ directory' do
        allow(Dir).to receive(:exist?).and_call_original
        allow(Dir).to receive(:exist?).with('engines/admin').and_return(false)
        allow(Dir).to receive(:exist?).with('components/admin').and_return(true)
        allow(File).to receive(:exist?).and_call_original
        allow(File).to receive(:exist?).with('components/admin/admin.gemspec').and_return(true)

        expect(generator.send(:detect_engine_path)).to eq('components/admin')
      end

      it 'returns nil when engine not found' do
        allow(Dir).to receive(:exist?).and_call_original
        allow(Dir).to receive(:exist?).with(anything).and_return(false)

        expect(generator.send(:detect_engine_path)).to be_nil
      end
    end

    describe '#engine_exists?' do
      it 'returns false when engine_path is nil' do
        generator = described_class.new([], setup: true)
        expect(generator.send(:engine_exists?)).to be false
      end

      it 'returns true when engine_path exists' do
        generator = described_class.new([], setup: true, engine: 'admin')
        allow(generator).to receive(:engine_path).and_return('engines/admin')

        expect(generator.send(:engine_exists?)).to be true
      end
    end

    describe '#path_app' do
      it 'returns "app" when no engine is set' do
        generator = described_class.new([], setup: true)
        expect(generator.send(:path_app)).to eq('app')
      end

      it 'returns engine app path when engine is set' do
        generator = described_class.new([], setup: true, engine: 'admin')
        allow(generator).to receive(:engine_path).and_return('engines/admin')

        expect(generator.send(:path_app)).to eq('engines/admin/app')
      end
    end

    describe '#validate_engine' do
      it 'does nothing when no engine option is set' do
        generator = described_class.new([], setup: true)
        expect { generator.validate_engine }.not_to raise_error
      end

      it 'raises error when engine does not exist' do
        generator = described_class.new([], setup: true, engine: 'nonexistent')
        allow(generator).to receive(:engine_exists?).and_return(false)
        allow(generator).to receive(:available_engines).and_return(['admin', 'api'])

        expect { generator.validate_engine }.to raise_error(Thor::Error, /Engine 'nonexistent' not found/)
      end

      it 'succeeds when engine exists' do
        generator = described_class.new([], setup: true, engine: 'admin')
        allow(generator).to receive(:engine_exists?).and_return(true)

        expect { generator.validate_engine }.not_to raise_error
      end
    end

    describe '#available_engines' do
      it 'returns empty array when no engines exist' do
        generator = described_class.new([], setup: true)
        allow(Dir).to receive(:exist?).and_return(false)

        expect(generator.send(:available_engines)).to eq([])
      end

      it 'returns list of available engines' do
        generator = described_class.new([], setup: true)

        allow(Dir).to receive(:exist?).and_call_original
        allow(Dir).to receive(:exist?).with('engines').and_return(true)
        allow(Dir).to receive(:glob).and_call_original
        allow(Dir).to receive(:glob).with('engines/*').and_return(['engines/admin', 'engines/api'])
        allow(Dir).to receive(:exist?).with('engines/admin').and_return(true)
        allow(Dir).to receive(:exist?).with('engines/api').and_return(true)
        allow(File).to receive(:exist?).and_call_original
        allow(File).to receive(:exist?).with('engines/admin/admin.gemspec').and_return(true)
        allow(File).to receive(:exist?).with('engines/api/api.gemspec').and_return(true)

        allow(Dir).to receive(:exist?).with('components').and_return(false)
        allow(Dir).to receive(:exist?).with('gems').and_return(false)
        allow(Dir).to receive(:exist?).with('.').and_return(true)
        allow(Dir).to receive(:glob).with('./*').and_return([])

        expect(generator.send(:available_engines)).to include('admin', 'api')
      end
    end
  end
end
