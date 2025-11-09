# frozen_string_literal: true

require 'fileutils'
require 'ostruct'
require 'generators/sun_sword/scaffold_generator'

RSpec.describe SunSword::ScaffoldGenerator, type: :generator do
  include FileUtils

  let(:destination_root) { File.expand_path('../tmp', __dir__) }

  let(:structure_file) { 'test_structure.yaml' }
  let(:structure_content) do
    {
      'model'             => 'TestModel',
      'resource_name'     => 'test_models',
      'actor'             => 'admin',
      'resource_owner_id' => 'user_id',
      'entity'            => {
        'skipped_fields' => ['created_at', 'updated_at'],
        'custom_fields'  => []
      },
      'domains'           => {
        'action_list'        => {
          'use_case' => {
            'contract' => ['name', 'email']
          }
        },
        'action_fetch_by_id' => {
          'use_case' => {
            'contract' => ['id', 'name', 'email']
          }
        },
        'action_create'      => {
          'use_case' => {
            'contract' => ['name', 'email']
          }
        },
        'action_update'      => {
          'use_case' => {
            'contract' => ['name', 'email']
          }
        },
        'action_destroy'     => {
          'use_case' => {
            'contract' => ['id']
          }
        }
      },
      'controllers'       => {
        'form_fields' => [
          { 'name' => 'name', 'type' => 'string' },
          { 'name' => 'email', 'type' => 'string' }
        ]
      }
    }.to_yaml
  end

  before do
    FileUtils.mkdir_p(destination_root) unless Dir.exist?(destination_root)
    # Create the required structure file
    FileUtils.mkdir_p(File.join(destination_root, 'db', 'structures'))
    File.write(File.join(destination_root, 'db', 'structures', structure_file), structure_content)
  end

  after do
    FileUtils.rm_rf(destination_root) if Dir.exist?(destination_root)
  end

  describe 'arguments' do
    it 'accepts structure argument' do
      generator = described_class.new(['test'])
      expect(generator.arg_structure).to eq('test')
    end

    it 'accepts scope argument' do
      generator = described_class.new(['test', 'scope:admin'])
      expect(generator.arg_scope).to eq({ 'scope' => 'admin' })
    end
  end

  describe 'source root' do
    it 'has the correct source root' do
      source_path = File.expand_path('templates_scaffold', File.dirname(__FILE__))
      expect(described_class.source_root).to eq(source_path)
    end
  end

  describe '#setup_variables' do
    let(:generator) do
      described_class.new(['test'], {}).tap do |g|
        g.destination_root = destination_root
      end
    end

    before do
      # Mock the model class
      stub_const('TestModel', Class.new)
      allow(TestModel).to receive(:columns).and_return([
                                                         double(name: 'id'),
                                                         double(name: 'name'),
                                                         double(name: 'email'),
                                                         double(name: 'created_at'),
                                                         double(name: 'updated_at')
                                                       ])
      allow(TestModel).to receive(:columns_hash).and_return({
        'id'    => double(type: :integer),
        'name'  => double(type: :string),
        'email' => double(type: :string)
      })
    end

    it 'loads structure configuration' do
      Dir.chdir(destination_root) do
        generator.send(:setup_variables)
        expect(generator.instance_variable_get(:@structure)).to be_a(Hashie::Mash)
      end
    end

    it 'sets actor from structure' do
      Dir.chdir(destination_root) do
        generator.send(:setup_variables)
        expect(generator.instance_variable_get(:@actor)).to eq('admin')
      end
    end

    it 'sets variable subject' do
      Dir.chdir(destination_root) do
        generator.send(:setup_variables)
        expect(generator.instance_variable_get(:@variable_subject)).to eq('test_model')
      end
    end

    it 'sets scope path' do
      Dir.chdir(destination_root) do
        generator.send(:setup_variables)
        expect(generator.instance_variable_get(:@scope_path)).to eq('test_models')
      end
    end
  end

  describe '#build_usecase_filename' do
    let(:generator) do
      described_class.new(['test'], {}).tap do |g|
        g.destination_root = destination_root
        g.instance_variable_set(:@actor, 'admin')
        g.instance_variable_set(:@variable_subject, 'testmodel')
      end
    end

    it 'builds filename with actor, action and subject' do
      result = generator.send(:build_usecase_filename, 'list')
      expect(result).to eq('AdminListTestmodel')
    end

    it 'appends suffix when provided' do
      result = generator.send(:build_usecase_filename, 'create', '_contract')
      expect(result).to eq('AdminCreateTestmodelContract')
    end
  end

  describe '#contract_fields' do
    let(:generator) do
      described_class.new(['test'], {}).tap do |g|
        g.destination_root = destination_root
        g.instance_variable_set(:@model_class, TestModel)
        g.instance_variable_set(:@skipped_fields, ['created_at', 'updated_at'])
      end
    end

    before do
      stub_const('TestModel', Class.new)
      allow(TestModel).to receive(:columns).and_return([
                                                         double(name: 'id'),
                                                         double(name: 'name'),
                                                         double(name: 'email'),
                                                         double(name: 'created_at'),
                                                         double(name: 'updated_at')
                                                       ])
    end

    it 'returns model columns excluding skipped fields' do
      result = generator.send(:contract_fields)
      expect(result).to contain_exactly('id', 'name', 'email')
    end
  end

  describe '#strong_params' do
    let(:generator) do
      described_class.new(['test'], {}).tap do |g|
        g.destination_root = destination_root
        g.instance_variable_set(:@controllers, Hashie::Mash.new({
          'form_fields' => [
            { 'name' => 'name', 'type' => 'string' },
            { 'name' => 'email', 'type' => 'string' },
            { 'name' => 'attachments', 'type' => 'files' }
          ]
        }))
        g.instance_variable_set(:@model_class, TestModel)
      end
    end

    before do
      stub_const('TestModel', Class.new)
      allow(TestModel).to receive(:columns_hash).and_return({
        'name'        => double(type: :string),
        'email'       => double(type: :string),
        'attachments' => double(type: :files)
      })
    end

    it 'generates strong params for different field types' do
      result = generator.send(:strong_params)
      expect(result).to include(':name')
      expect(result).to include(':email')
      expect(result).to include('{ attachments: [] }')
    end
  end

  describe '#namespace_exists?' do
    let(:generator) do
      described_class.new(['test'], {}).tap do |g|
        g.destination_root = destination_root
        g.instance_variable_set(:@route_scope_path, 'admin')
      end
    end

    before do
      FileUtils.mkdir_p(File.join(destination_root, 'config'))
    end

    context 'when routes file exists and contains namespace' do
      before do
        routes_content = <<~RUBY
          Rails.application.routes.draw do
            namespace :admin do
            end
          end
        RUBY
        File.write(File.join(destination_root, 'config', 'routes.rb'), routes_content)
      end

      it 'returns true' do
        Dir.chdir(destination_root) do
          result = generator.send(:namespace_exists?)
          expect(result).to be true
        end
      end
    end

    context 'when routes file exists but does not contain namespace' do
      before do
        routes_content = <<~RUBY
          Rails.application.routes.draw do
          end
        RUBY
        File.write(File.join(destination_root, 'config', 'routes.rb'), routes_content)
      end

      it 'returns false' do
        Dir.chdir(destination_root) do
          result = generator.send(:namespace_exists?)
          expect(result).to be false
        end
      end
    end

    context 'when routes file does not exist' do
      it 'returns false' do
        Dir.chdir(destination_root) do
          result = generator.send(:namespace_exists?)
          expect(result).to be false
        end
      end
    end
  end

  describe 'engine support' do
    describe '#engine_path' do
      it 'returns nil when no engine option is set' do
        generator = described_class.new(['test'], {})
        expect(generator.send(:engine_path)).to be_nil
      end

      it 'returns engine path when engine option is set' do
        generator = described_class.new(['test'], { engine: 'admin' })
        allow(generator).to receive(:detect_engine_path).and_return('engines/admin')

        expect(generator.send(:engine_path)).to eq('engines/admin')
      end
    end

    describe '#detect_engine_path' do
      let(:generator) { described_class.new(['test'], { engine: 'admin' }) }

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

    describe '#path_app' do
      it 'returns "app" when no engine is set' do
        generator = described_class.new(['test'], {})
        expect(generator.send(:path_app)).to eq('app')
      end

      it 'returns engine app path when engine is set' do
        generator = described_class.new(['test'], { engine: 'admin' })
        allow(generator).to receive(:engine_path).and_return('engines/admin')

        expect(generator.send(:path_app)).to eq('engines/admin/app')
      end
    end

    describe '#structure_file_path' do
      it 'returns default path when no engine options' do
        generator = described_class.new(['test'], {})
        generator.instance_variable_set(:@arg_structure, 'user')

        expect(generator.send(:structure_file_path)).to eq('db/structures/user_structure.yaml')
      end

      it 'returns engine path when engine_structure option is set' do
        generator = described_class.new(['test'], { engine_structure: 'core' })
        generator.instance_variable_set(:@arg_structure, 'user')

        allow(generator).to receive(:detect_structure_engine_path).and_return('engines/core')

        expect(generator.send(:structure_file_path)).to eq('engines/core/db/structures/user_structure.yaml')
      end

      it 'uses engine option as fallback for structure path' do
        generator = described_class.new(['test'], { engine: 'admin' })
        generator.instance_variable_set(:@arg_structure, 'user')

        allow(generator).to receive(:detect_structure_engine_path).and_return('engines/admin')

        expect(generator.send(:structure_file_path)).to eq('engines/admin/db/structures/user_structure.yaml')
      end

      it 'raises error when structure engine not found' do
        generator = described_class.new(['test'], { engine_structure: 'nonexistent' })
        generator.instance_variable_set(:@arg_structure, 'user')

        allow(generator).to receive(:detect_structure_engine_path).and_return(nil)

        expect { generator.send(:structure_file_path) }.to raise_error(Thor::Error, /Structure file not found/)
      end
    end

    describe '#routes_file_path' do
      it 'returns default path when no engine' do
        generator = described_class.new(['test'], {})
        expect(generator.send(:routes_file_path)).to eq('config/routes.rb')
      end

      it 'returns engine routes path when engine is set' do
        generator = described_class.new(['test'], { engine: 'admin' })
        allow(generator).to receive(:engine_path).and_return('engines/admin')

        expect(generator.send(:routes_file_path)).to eq('engines/admin/config/routes.rb')
      end
    end

    describe '#validate_engine' do
      it 'does nothing when no engine option is set' do
        generator = described_class.new(['test'], {})
        expect { generator.validate_engine }.not_to raise_error
      end

      it 'raises error when engine does not exist' do
        generator = described_class.new(['test'], { engine: 'nonexistent' })
        allow(generator).to receive(:engine_exists?).and_return(false)
        allow(generator).to receive(:available_engines).and_return(['admin', 'api'])

        expect { generator.validate_engine }.to raise_error(Thor::Error, /Engine 'nonexistent' not found/)
      end

      it 'succeeds when engine exists' do
        generator = described_class.new(['test'], { engine: 'admin' })
        allow(generator).to receive(:engine_exists?).and_return(true)

        expect { generator.validate_engine }.not_to raise_error
      end
    end

    describe '#detect_structure_engine_path' do
      let(:generator) { described_class.new(['test'], { engine_structure: 'core' }) }

      it 'detects structure directory in engine' do
        allow(Dir).to receive(:exist?).and_call_original
        allow(Dir).to receive(:exist?).with('engines/core/db/structures').and_return(true)

        expect(generator.send(:detect_structure_engine_path)).to eq('engines/core')
      end

      it 'returns nil when structure directory not found' do
        allow(Dir).to receive(:exist?).and_call_original
        allow(Dir).to receive(:exist?).with(anything).and_return(false)

        expect(generator.send(:detect_structure_engine_path)).to be_nil
      end
    end
  end

  describe 'spec file generation' do
    let(:test_model_class) do
      Class.new do
        def self.name
          'TestModel'
        end

        def self.columns
          [
            OpenStruct.new(name: 'id', type: :integer),
            OpenStruct.new(name: 'name', type: :string),
            OpenStruct.new(name: 'email', type: :string)
          ]
        end

        def self.create!(attrs)
          new
        end

        def self.new
          Object.new
        end
      end
    end

    let(:generator) do
      described_class.new(['test'], {}).tap do |g|
        g.destination_root = destination_root
      end
    end

    before do
      mkdir_p(destination_root)
      mkdir_p(File.join(destination_root, 'db', 'structures'))
      File.write(File.join(destination_root, 'db', 'structures', structure_file), structure_content)

      # Stub the model class
      stub_const('TestModel', test_model_class)
    end

    after do
      rm_rf(destination_root) if Dir.exist?(destination_root)
    end

    describe '#create_spec_files' do
      it 'generates controller spec file in same directory as controller' do
        Dir.chdir(destination_root) do
          generator.send(:setup_variables)
          generator.send(:create_spec_files)

          controller_spec_path = File.join(destination_root, 'app', 'controllers', '', 'test_models_controller_spec.rb')
          expect(File.exist?(controller_spec_path)).to be true
        end
      end

      it 'controller spec contains correct class name' do
        Dir.chdir(destination_root) do
          generator.send(:setup_variables)
          generator.send(:create_spec_files)

          controller_spec_path = File.join(destination_root, 'app', 'controllers', '', 'test_models_controller_spec.rb')
          content = File.read(controller_spec_path)
          expect(content).to include('RSpec.describe TestModelsController')
        end
      end

      it 'controller spec contains CRUD action tests with use case mocking' do
        Dir.chdir(destination_root) do
          generator.send(:setup_variables)
          generator.send(:create_spec_files)

          controller_spec_path = File.join(destination_root, 'app', 'controllers', '', 'test_models_controller_spec.rb')
          content = File.read(controller_spec_path)

          expect(content).to include('GET #index')
          expect(content).to include('GET #show')
          expect(content).to include('GET #new')
          expect(content).to include('GET #edit')
          expect(content).to include('POST #create')
          expect(content).to include('PATCH #update')
          expect(content).to include('DELETE #destroy')
          expect(content).to include('instance_double')
          expect(content).to include('Dry::Monads::Success')
          expect(content).to include('Dry::Monads::Failure')
        end
      end

      it 'controller spec includes private methods tests' do
        Dir.chdir(destination_root) do
          generator.send(:setup_variables)
          generator.send(:create_spec_files)

          controller_spec_path = File.join(destination_root, 'app', 'controllers', '', 'test_models_controller_spec.rb')
          content = File.read(controller_spec_path)

          expect(content).to include('private methods')
          expect(content).to include('#build_contract')
          expect(content).to include('#set_test_model')
          expect(content).to include('#test_model_params')
        end
      end
    end

    describe 'spec file generation with scope' do
      let(:generator_with_scope) do
        described_class.new(['test', 'scope:admin'], {}).tap do |g|
          g.destination_root = destination_root
        end
      end

      it 'generates controller spec in correct scope directory' do
        Dir.chdir(destination_root) do
          generator_with_scope.send(:setup_variables)
          generator_with_scope.send(:create_spec_files)

          controller_spec_path = File.join(destination_root, 'app', 'controllers', 'admin', 'test_models_controller_spec.rb')
          expect(File.exist?(controller_spec_path)).to be true
        end
      end

      it 'controller spec includes scoped class name and use case paths' do
        Dir.chdir(destination_root) do
          generator_with_scope.send(:setup_variables)
          generator_with_scope.send(:create_spec_files)

          controller_spec_path = File.join(destination_root, 'app', 'controllers', 'admin', 'test_models_controller_spec.rb')
          content = File.read(controller_spec_path)
          expect(content).to include('RSpec.describe Admin::TestModelsController')
          expect(content).to include('Core::UseCases::Admin')
        end
      end
    end

    describe 'spec file generation for engine' do
      let(:generator_with_engine) do
        described_class.new(['test'], { engine: 'admin' }).tap do |g|
          g.destination_root = destination_root
        end
      end

      before do
        mkdir_p(File.join(destination_root, 'engines', 'admin'))
        mkdir_p(File.join(destination_root, 'engines', 'admin', 'db', 'structures'))
        File.write(File.join(destination_root, 'engines', 'admin', 'db', 'structures', structure_file), structure_content)
        mkdir_p(File.join(destination_root, 'db', 'structures'))
        File.write(File.join(destination_root, 'db', 'structures', structure_file), structure_content)

        stub_const('TestModel', test_model_class)
        allow(generator_with_engine).to receive(:engine_path).and_return('engines/admin')
        allow(generator_with_engine).to receive(:engine_exists?).and_return(true)
        allow(generator_with_engine).to receive(:detect_structure_engine_path).and_return(nil)
        allow(generator_with_engine).to receive(:structure_file_path).and_return(File.join('db', 'structures', structure_file))
      end

      it 'generates controller spec in engine directory' do
        Dir.chdir(destination_root) do
          generator_with_engine.send(:setup_variables)
          generator_with_engine.send(:create_spec_files)

          controller_spec_path = File.join(destination_root, 'engines', 'admin', 'app', 'controllers', '', 'test_models_controller_spec.rb')
          expect(File.exist?(controller_spec_path)).to be true
        end
      end

      it 'controller spec contains use case mocking and factory bot' do
        Dir.chdir(destination_root) do
          generator_with_engine.send(:setup_variables)
          generator_with_engine.send(:create_spec_files)

          controller_spec_path = File.join(destination_root, 'engines', 'admin', 'app', 'controllers', '', 'test_models_controller_spec.rb')
          content = File.read(controller_spec_path)
          expect(content).to include('instance_double')
          expect(content).to include('create(:')
          expect(content).to include('build(:')
        end
      end
    end
  end
end
