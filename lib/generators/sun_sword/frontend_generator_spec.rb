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

    it 'rejects engine option' do
      generator = described_class.new([], setup: true, engine: 'admin')
      expect {
        generator.validate_no_engine
      }.to raise_error(Thor::Error, 'Frontend generator does not support --engine option. Frontend setup must be done in the main app only. Use "rails generate sun_sword:frontend --setup" without engine option.')
    end

    it 'accepts setup without engine option' do
      generator = described_class.new([], setup: true, engine: nil)
      expect {
        generator.validate_no_engine
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

  describe '#setup' do
    let(:generator) do
      described_class.new([], setup: true).tap do |g|
        g.destination_root = destination_root
      end
    end

    before do
      # Mock all dependencies
      allow(generator).to receive(:copy_assets_from_template)
      allow(generator).to receive(:add_to_gemfile)
      allow(generator).to receive(:install_vite)
      allow(generator).to receive(:configure_vite)
      allow(generator).to receive(:modify_application_js)
      allow(generator).to receive(:generate_default_frontend)
      allow(generator).to receive(:generate_controllers_tests)
      allow(generator).to receive(:generate_components)
      allow(generator).to receive(:modify_layout_for_vite)
    end

    it 'validates no engine option before setup' do
      generator_with_engine = described_class.new([], setup: true, engine: 'admin')
      expect {
        generator_with_engine.setup
      }.to raise_error(Thor::Error, /Frontend generator does not support --engine option/)
    end

    it 'calls all methods in correct order' do
      generator.setup

      expect(generator).to have_received(:copy_assets_from_template).ordered
      expect(generator).to have_received(:add_to_gemfile).ordered
      expect(generator).to have_received(:install_vite).ordered
      expect(generator).to have_received(:configure_vite).ordered
      expect(generator).to have_received(:modify_application_js).ordered
      expect(generator).to have_received(:generate_default_frontend).ordered
      expect(generator).to have_received(:generate_controllers_tests).ordered
      expect(generator).to have_received(:generate_components).ordered
      expect(generator).to have_received(:modify_layout_for_vite).ordered
    end

    it 'calls all required methods' do
      generator.setup

      expect(generator).to have_received(:copy_assets_from_template)
      expect(generator).to have_received(:add_to_gemfile)
      expect(generator).to have_received(:install_vite)
      expect(generator).to have_received(:configure_vite)
      expect(generator).to have_received(:modify_application_js)
      expect(generator).to have_received(:generate_default_frontend)
      expect(generator).to have_received(:generate_controllers_tests)
      expect(generator).to have_received(:generate_components)
      expect(generator).to have_received(:modify_layout_for_vite)
    end
  end

  describe '#remove_assets_folder' do
    let(:generator) do
      described_class.new([], setup: true).tap do |g|
        g.destination_root = destination_root
      end
    end

    context 'when assets folder exists' do
      before do
        FileUtils.mkdir_p(File.join(destination_root, 'app', 'assets'))
      end

      it 'removes the folder' do
        allow(generator).to receive(:remove_dir)
        allow(generator).to receive(:say)

        Dir.chdir(destination_root) do
          generator.send(:remove_assets_folder)
        end

        expect(generator).to have_received(:remove_dir).with('app/assets')
        expect(generator).to have_received(:say).with("Folder 'app/assets' has been removed.", :green)
      end
    end

    context 'when assets folder does not exist' do
      it 'handles gracefully without removing' do
        allow(generator).to receive(:remove_dir)
        allow(generator).to receive(:say)

        Dir.chdir(destination_root) do
          generator.send(:remove_assets_folder)
        end

        expect(generator).not_to have_received(:remove_dir)
        expect(generator).to have_received(:say).with("Folder 'app/assets' does not exist.", :yellow)
      end
    end
  end

  describe '#install_vite' do
    let(:generator) do
      described_class.new([], setup: true).tap do |g|
        g.destination_root = destination_root
      end
    end

    before do
      allow(generator).to receive(:template)
      allow(generator).to receive(:run)
      allow(generator).to receive(:say)
    end

    it 'calls template for package.json' do
      generator.send(:install_vite)

      expect(generator).to have_received(:template).with('package.json.tt', 'package.json')
    end

    it 'runs bun install' do
      generator.send(:install_vite)

      expect(generator).to have_received(:run).with('bun install')
    end

    it 'runs all bun add commands' do
      generator.send(:install_vite)

      expect(generator).to have_received(:run).with('bun add -D vite vite-plugin-full-reload vite-plugin-ruby vite-plugin-stimulus-hmr')
      expect(generator).to have_received(:run).with('bun add path stimulus-vite-helpers @hotwired/stimulus @hotwired/turbo-rails @tailwindcss/aspect-ratio @tailwindcss/forms @tailwindcss/line-clamp @tailwindcss/typography @tailwindcss/vite tailwindcss vite-plugin-rails autoprefixer')
      expect(generator).to have_received(:run).with('bun add -D eslint prettier eslint-plugin-prettier eslint-config-prettier eslint-plugin-tailwindcss')
    end

    it 'displays success message' do
      generator.send(:install_vite)

      expect(generator).to have_received(:say).with('Vite installed successfully with Bun', :green)
    end
  end

  describe '#configure_vite' do
    let(:generator) do
      described_class.new([], setup: true).tap do |g|
        g.destination_root = destination_root
      end
    end

    before do
      allow(generator).to receive(:template)
      allow(generator).to receive(:run)
      allow(generator).to receive(:say)
    end

    it 'calls template for all vite config files' do
      generator.send(:configure_vite)

      expect(generator).to have_received(:template).with('vite.config.ts.tt', 'vite.config.ts')
      expect(generator).to have_received(:template).with('Procfile.dev.tt', 'Procfile.dev')
      expect(generator).to have_received(:template).with('bin/watch.tt', 'bin/watch')
      expect(generator).to have_received(:template).with('config/vite.json.tt', 'config/vite.json')
      expect(generator).to have_received(:template).with('env.development.tt', '.env.development')
    end

    it 'runs chmod command for bin/watch' do
      generator.send(:configure_vite)

      expect(generator).to have_received(:run).with('chmod +x bin/watch')
    end

    it 'displays configuration messages' do
      generator.send(:configure_vite)

      expect(generator).to have_received(:say).with('Configuring Vite...')
      expect(generator).to have_received(:say).with('Vite configuration completed', :green)
    end
  end

  describe '#modify_application_js' do
    let(:generator) do
      described_class.new([], setup: true).tap do |g|
        g.destination_root = destination_root
      end
    end

    before do
      allow(generator).to receive(:say)
    end

    context 'when application.js exists' do
      before do
        FileUtils.mkdir_p(File.join(destination_root, 'app', 'javascript'))
        FileUtils.touch(File.join(destination_root, 'app', 'javascript', 'application.js'))
      end

      it 'displays update message' do
        Dir.chdir(destination_root) do
          generator.send(:modify_application_js)
        end

        expect(generator).to have_received(:say).with('Updated application.js for Vite', :green)
      end
    end

    context 'when application.js does not exist' do
      it 'does not display update message' do
        Dir.chdir(destination_root) do
          generator.send(:modify_application_js)
        end

        expect(generator).not_to have_received(:say).with('Updated application.js for Vite', :green)
      end
    end
  end

  describe '#generate_default_frontend' do
    let(:generator) do
      described_class.new([], setup: true).tap do |g|
        g.destination_root = destination_root
      end
    end

    before do
      allow(generator).to receive(:directory)
      allow(generator).to receive(:say)
    end

    it 'calls directory with correct paths' do
      generator.send(:generate_default_frontend)

      expect(generator).to have_received(:directory).with('frontend', File.join('app', 'frontend'))
    end

    it 'displays success message' do
      generator.send(:generate_default_frontend)

      expect(generator).to have_received(:say).with('Generated default frontend files', :green)
    end
  end

  describe '#generate_components' do
    let(:generator) do
      described_class.new([], setup: true).tap do |g|
        g.destination_root = destination_root
      end
    end

    before do
      allow(generator).to receive(:directory)
      allow(generator).to receive(:say)
    end

    it 'calls directory with correct paths' do
      generator.send(:generate_components)

      expect(generator).to have_received(:directory).with('views/components', File.join('app', 'views/components'))
    end

    it 'displays success message' do
      generator.send(:generate_components)

      expect(generator).to have_received(:say).with('Generate default controller', :green)
    end
  end

  describe '#generate_controllers_tests' do
    let(:generator) do
      described_class.new([], setup: true).tap do |g|
        g.destination_root = destination_root
      end
    end

    before do
      FileUtils.mkdir_p(File.join(destination_root, 'config'))
      FileUtils.touch(File.join(destination_root, 'config', 'routes.rb'))
      File.write(File.join(destination_root, 'config', 'routes.rb'), "Rails.application.routes.draw do\nend\n")

      allow(generator).to receive(:run)
      allow(generator).to receive(:template)
      allow(generator).to receive(:copy_file)
      allow(generator).to receive(:inject_into_file)
      allow(generator).to receive(:say)
    end

    it 'runs rails generator command' do
      generator.send(:generate_controllers_tests)

      expect(generator).to have_received(:run).with('rails g controller tests stimulus turbo_drive turbo_frame frame_content update_content')
    end

    it 'calls template for controller files' do
      generator.send(:generate_controllers_tests)

      expect(generator).to have_received(:template).with('controllers/tests_controller.rb', File.join('app', 'controllers/tests_controller.rb'))
      expect(generator).to have_received(:template).with('controllers/tests_controller_spec.rb', File.join('app', 'controllers/tests_controller_spec.rb'))
    end

    it 'calls template for test views' do
      generator.send(:generate_controllers_tests)

      expect(generator).to have_received(:template).with('views/tests/stimulus.html.erb.tt', File.join('app', 'views/tests/stimulus.html.erb'))
      expect(generator).to have_received(:template).with('views/tests/_comment.html.erb.tt', File.join('app', 'views/tests/_comment.html.erb'))
    end

    it 'copies test view files' do
      generator.send(:generate_controllers_tests)

      expect(generator).to have_received(:copy_file).with('views/tests/turbo_drive.html.erb', File.join('app', 'views/tests/turbo_drive.html.erb'))
      expect(generator).to have_received(:copy_file).with('views/tests/turbo_frame.html.erb', File.join('app', 'views/tests/turbo_frame.html.erb'))
      expect(generator).to have_received(:copy_file).with('views/tests/_frame_content.html.erb', File.join('app', 'views/tests/_frame_content.html.erb'))
      expect(generator).to have_received(:copy_file).with('views/tests/_updated_content.html.erb', File.join('app', 'views/tests/_updated_content.html.erb'))
      expect(generator).to have_received(:copy_file).with('views/tests/_log_entry.html.erb', File.join('app', 'views/tests/_log_entry.html.erb'))
    end

    it 'injects routes into routes.rb' do
      Dir.chdir(destination_root) do
        generator.send(:generate_controllers_tests)
      end

      expect(generator).to have_received(:inject_into_file).with('config/routes.rb', anything, after: "Rails.application.routes.draw do\n")
    end

    it 'displays success message' do
      generator.send(:generate_controllers_tests)

      expect(generator).to have_received(:say).with('Generate tests controller for frontend feature testing', :green)
    end
  end

  describe '#app_name' do
    let(:generator) do
      described_class.new([], setup: true).tap do |g|
        g.destination_root = destination_root
      end
    end

    context 'with valid Rails application name' do
      before do
        stub_const('Rails', Class.new)
        allow(Rails).to receive_message_chain(:application, :class, :module_parent_name).and_return('TestApp')
      end

      it 'returns underscored application name' do
        result = generator.send(:app_name)
        expect(result).to eq('test_app')
      end

      it 'memoizes the result' do
        first_call = generator.send(:app_name)
        second_call = generator.send(:app_name)

        expect(first_call).to eq(second_call)
        expect(generator.instance_variable_get(:@app_name)).to eq('test_app')
      end
    end

    context 'when error occurs' do
      before do
        stub_const('Rails', Class.new)
        allow(Rails).to receive_message_chain(:application, :class, :module_parent_name).and_raise(StandardError)
      end

      it 'falls back to app' do
        result = generator.send(:app_name)
        expect(result).to eq('app')
      end
    end
  end

  describe '#source_code_dir' do
    let(:generator) do
      described_class.new([], setup: true).tap do |g|
        g.destination_root = destination_root
      end
    end

    it 'returns app/frontend' do
      result = generator.send(:source_code_dir)
      expect(result).to eq('app/frontend')
    end

    it 'memoizes the result' do
      first_call = generator.send(:source_code_dir)
      second_call = generator.send(:source_code_dir)

      expect(first_call).to eq(second_call)
      expect(generator.instance_variable_get(:@source_code_dir)).to eq('app/frontend')
    end
  end

  describe '#modify_layout_for_vite' do
    let(:generator) do
      described_class.new([], setup: true).tap do |g|
        g.destination_root = destination_root
      end
    end

    before do
      allow(generator).to receive(:template)
      allow(generator).to receive(:directory)
      allow(generator).to receive(:say)
    end

    it 'calls template for all layout files' do
      generator.send(:modify_layout_for_vite)

      expect(generator).to have_received(:template).with('views/layouts/application.html.erb.tt', File.join('app', 'views/layouts/application.html.erb'))
      expect(generator).to have_received(:template).with('views/layouts/dashboard/application.html.erb.tt', File.join('app', 'views/layouts/owner/application.html.erb'))
      expect(generator).to have_received(:template).with('views/layouts/dashboard/_sidebar.html.erb.tt', File.join('app', 'views/components/layouts/_sidebar.html.erb'))
    end

    it 'calls directory for helpers' do
      generator.send(:modify_layout_for_vite)

      expect(generator).to have_received(:directory).with('helpers', File.join('app', 'helpers'))
    end

    it 'displays success message' do
      generator.send(:modify_layout_for_vite)

      expect(generator).to have_received(:say).with('Updated application layout for Vite integration', :green)
    end
  end
end
