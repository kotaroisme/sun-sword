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
                                                         double(name: 'id', type: :integer),
                                                         double(name: 'name', type: :string),
                                                         double(name: 'email', type: :string),
                                                         double(name: 'created_at', type: :datetime),
                                                         double(name: 'updated_at', type: :datetime)
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
                                                         double(name: 'id', type: :integer),
                                                         double(name: 'name', type: :string),
                                                         double(name: 'email', type: :string),
                                                         double(name: 'created_at', type: :datetime),
                                                         double(name: 'updated_at', type: :datetime)
                                                       ])
    end

    it 'returns model columns excluding skipped fields as tuples [name, type]' do
      result = generator.send(:contract_fields)
      expect(result).to contain_exactly(['id', 'integer'], ['name', 'string'], ['email', 'string'])
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
        g.instance_variable_set(:@engine_scope_path, 'admin')
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

        allow(generator).to receive(:detect_structure_engine_path).with('core').and_return('engines/core')

        expect(generator.send(:structure_file_path)).to eq('engines/core/db/structures/user_structure.yaml')
      end

      it 'uses engine option as fallback for structure path' do
        generator = described_class.new(['test'], { engine: 'admin' })
        generator.instance_variable_set(:@arg_structure, 'user')

        allow(generator).to receive(:detect_structure_engine_path).with('admin').and_return('engines/admin')

        expect(generator.send(:structure_file_path)).to eq('engines/admin/db/structures/user_structure.yaml')
      end

      it 'raises error when structure engine not found' do
        generator = described_class.new(['test'], { engine_structure: 'nonexistent' })
        generator.instance_variable_set(:@arg_structure, 'user')

        allow(generator).to receive(:detect_structure_engine_path).with('nonexistent').and_return(nil)

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
      it 'detects structure directory in engine' do
        generator = described_class.new(['test'], {})
        allow(Dir).to receive(:exist?).and_call_original
        allow(Dir).to receive(:exist?).with('engines/core/db/structures').and_return(true)

        expect(generator.send(:detect_structure_engine_path, 'core')).to eq('engines/core')
      end

      it 'returns nil when structure directory not found' do
        generator = described_class.new(['test'], {})
        allow(Dir).to receive(:exist?).and_call_original
        allow(Dir).to receive(:exist?).with(anything).and_return(false)

        expect(generator.send(:detect_structure_engine_path, 'core')).to be_nil
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
        allow(generator_with_engine).to receive(:detect_structure_engine_path).with(any_args).and_return(nil)
        allow(generator_with_engine).to receive(:structure_file_path).and_return(File.join('db', 'structures', structure_file))
      end

      it 'generates controller spec in engine directory' do
        Dir.chdir(destination_root) do
          generator_with_engine.send(:setup_variables)
          generator_with_engine.send(:create_spec_files)

          controller_spec_path = File.join(destination_root, 'engines', 'admin', 'app', 'controllers', 'admin', 'test_models_controller_spec.rb')
          expect(File.exist?(controller_spec_path)).to be true
        end
      end

      it 'controller spec contains use case mocking and factory bot' do
        Dir.chdir(destination_root) do
          generator_with_engine.send(:setup_variables)
          generator_with_engine.send(:create_spec_files)

          controller_spec_path = File.join(destination_root, 'engines', 'admin', 'app', 'controllers', 'admin', 'test_models_controller_spec.rb')
          content = File.read(controller_spec_path)
          expect(content).to include('instance_double')
          expect(content).to include('create(:')
          expect(content).to include('build(:')
        end
      end
    end
  end

  describe '#generate_form_fields_html' do
    let(:generator) do
      described_class.new(['test'], {}).tap do |g|
        g.destination_root = destination_root
        g.instance_variable_set(:@variable_subject, 'test_model')
        g.instance_variable_set(:@mapping_fields, {
          string:    :text_field,
          text:      :text_area,
          integer:   :number_field,
          float:     :number_field,
          decimal:   :number_field,
          boolean:   :check_box,
          date:      :date_select,
          datetime:  :datetime_select,
          timestamp: :datetime_select,
          time:      :time_select,
          enum:      :select,
          file:      :file_field,
          files:     :file_fields
        })
      end
    end

    context 'with text_field (string type)' do
      before do
        generator.instance_variable_set(:@form_fields, [
                                          { name: 'name', type: 'string' }
                                        ])
      end

      it 'generates text_field HTML' do
        result = generator.send(:generate_form_fields_html)

        expect(result).to include('form.text_field :name')
        expect(result).to include("id: 'test_model_name'")
        expect(result).to include("for: 'test_model_name'")
      end
    end

    context 'with text_area (text type)' do
      before do
        generator.instance_variable_set(:@form_fields, [
                                          { name: 'description', type: 'text' }
                                        ])
      end

      it 'generates text_area HTML' do
        result = generator.send(:generate_form_fields_html)

        expect(result).to include('form.text_area :description')
        expect(result).to include("id: 'test_model_description'")
        expect(result).to include('rows: 3')
      end
    end

    context 'with number_field (integer type)' do
      before do
        generator.instance_variable_set(:@form_fields, [
                                          { name: 'age', type: 'integer' }
                                        ])
      end

      it 'generates number_field HTML' do
        result = generator.send(:generate_form_fields_html)

        expect(result).to include('form.number_field :age')
        expect(result).to include("id: 'test_model_age'")
      end
    end

    context 'with number_field (float type)' do
      before do
        generator.instance_variable_set(:@form_fields, [
                                          { name: 'price', type: 'float' }
                                        ])
      end

      it 'generates number_field HTML' do
        result = generator.send(:generate_form_fields_html)

        expect(result).to include('form.number_field :price')
      end
    end

    context 'with number_field (decimal type)' do
      before do
        generator.instance_variable_set(:@form_fields, [
                                          { name: 'amount', type: 'decimal' }
                                        ])
      end

      it 'generates number_field HTML' do
        result = generator.send(:generate_form_fields_html)

        expect(result).to include('form.number_field :amount')
      end
    end

    context 'with check_box (boolean type)' do
      before do
        generator.instance_variable_set(:@form_fields, [
                                          { name: 'active', type: 'boolean' }
                                        ])
      end

      it 'generates check_box HTML' do
        result = generator.send(:generate_form_fields_html)

        expect(result).to include('form.check_box :active')
        expect(result).to include("id: 'test_model_active'")
        expect(result).to include('relative flex items-start')
      end
    end

    context 'with select (enum type)' do
      before do
        generator.instance_variable_set(:@form_fields, [
                                          { name: 'status', type: 'enum' }
                                        ])
      end

      it 'generates select HTML' do
        result = generator.send(:generate_form_fields_html)

        expect(result).to include('form.select :status')
        expect(result).to include("id: 'test_model_status'")
        expect(result).to include('options_for_select')
      end
    end

    context 'with date_select (date type)' do
      before do
        generator.instance_variable_set(:@form_fields, [
                                          { name: 'birthday', type: 'date' }
                                        ])
      end

      it 'generates date_select HTML with correct label_input_id' do
        result = generator.send(:generate_form_fields_html)

        expect(result).to include('form.date_select :birthday')
        expect(result).to include("for: 'test_model_birthday_1i'")
        expect(result).to include("id_prefix: 'test_model_birthday'")
      end
    end

    context 'with datetime_select (datetime type)' do
      before do
        generator.instance_variable_set(:@form_fields, [
                                          { name: 'created_at', type: 'datetime' }
                                        ])
      end

      it 'generates datetime_select HTML with correct label_input_id' do
        result = generator.send(:generate_form_fields_html)

        expect(result).to include('form.datetime_select :created_at')
        expect(result).to include("for: 'test_model_created_at_1i'")
        expect(result).to include("id_prefix: 'test_model_created_at'")
      end
    end

    context 'with datetime_select (timestamp type)' do
      before do
        generator.instance_variable_set(:@form_fields, [
                                          { name: 'updated_at', type: 'timestamp' }
                                        ])
      end

      it 'generates datetime_select HTML' do
        result = generator.send(:generate_form_fields_html)

        expect(result).to include('form.datetime_select :updated_at')
        expect(result).to include("for: 'test_model_updated_at_1i'")
      end
    end

    context 'with time_select (time type)' do
      before do
        generator.instance_variable_set(:@form_fields, [
                                          { name: 'start_time', type: 'time' }
                                        ])
      end

      it 'generates time_select HTML with correct label_input_id' do
        result = generator.send(:generate_form_fields_html)

        expect(result).to include('form.time_select :start_time')
        expect(result).to include("for: 'test_model_start_time_4i'")
        expect(result).to include("id_prefix: 'test_model_start_time'")
      end
    end

    context 'with file_field (file type)' do
      before do
        generator.instance_variable_set(:@form_fields, [
                                          { name: 'avatar', type: 'file' }
                                        ])
      end

      it 'generates file_field HTML' do
        result = generator.send(:generate_form_fields_html)

        expect(result).to include('form.file_field :avatar')
        expect(result).to include("id: 'test_model_avatar'")
        expect(result).to include('border border-dashed')
        expect(result).not_to include('multiple: true')
      end
    end

    context 'with file_fields (files type)' do
      before do
        generator.instance_variable_set(:@form_fields, [
                                          { name: 'attachments', type: 'files' }
                                        ])
      end

      it 'generates file_field HTML with multiple' do
        result = generator.send(:generate_form_fields_html)

        expect(result).to include('form.file_field :attachments')
        expect(result).to include("id: 'test_model_attachments'")
        expect(result).to include('multiple: true')
      end
    end

    context 'with multiple fields' do
      before do
        generator.instance_variable_set(:@form_fields, [
                                          { name: 'name', type: 'string' },
                                          { name: 'email', type: 'string' },
                                          { name: 'active', type: 'boolean' }
                                        ])
      end

      it 'generates HTML for all fields' do
        result = generator.send(:generate_form_fields_html)

        expect(result).to include('form.text_field :name')
        expect(result).to include('form.text_field :email')
        expect(result).to include('form.check_box :active')
      end
    end

    context 'with empty form_fields' do
      before do
        generator.instance_variable_set(:@form_fields, [])
      end

      it 'returns empty string' do
        result = generator.send(:generate_form_fields_html)

        expect(result).to eq('')
      end
    end

    context 'with unknown field type' do
      before do
        generator.instance_variable_set(:@form_fields, [
                                          { name: 'custom_field', type: 'unknown' }
                                        ])
      end

      it 'falls back to text_field' do
        result = generator.send(:generate_form_fields_html)

        expect(result).to include('form.text_field :custom_field')
      end
    end

    context 'HTML structure' do
      before do
        generator.instance_variable_set(:@form_fields, [
                                          { name: 'name', type: 'string' }
                                        ])
      end

      it 'includes proper div structure' do
        result = generator.send(:generate_form_fields_html)

        expect(result).to include('sm:grid sm:grid-cols-3')
        expect(result).to include('sm:items-start')
        expect(result).to include('mt-2 sm:col-span-2 sm:mt-0')
        expect(result).to include('</div>')
      end
    end
  end

  describe '#create_root_folder' do
    let(:generator) do
      described_class.new(['test'], {}).tap do |g|
        g.destination_root = destination_root
        g.instance_variable_set(:@engine_scope_path, '')
        g.instance_variable_set(:@scope_path, 'test_models')
      end
    end

    before do
      allow(generator).to receive(:empty_directory)
    end

    it 'calls empty_directory with correct path' do
      generator.send(:create_root_folder)

      expect(generator).to have_received(:empty_directory).with(
                             File.join('app', 'views', '', 'test_models')
      )
    end

    context 'with engine scope' do
      before do
        generator.instance_variable_set(:@engine_scope_path, 'admin')
        allow(generator).to receive(:path_app).and_return('app')
      end

      it 'calls empty_directory with engine path' do
        generator.send(:create_root_folder)

        expect(generator).to have_received(:empty_directory).with(
                               File.join('app', 'views', 'admin', 'test_models')
        )
      end
    end

    context 'with route scope' do
      before do
        generator.instance_variable_set(:@engine_scope_path, 'dashboard')
        allow(generator).to receive(:path_app).and_return('app')
      end

      it 'calls empty_directory with scope path' do
        generator.send(:create_root_folder)

        expect(generator).to have_received(:empty_directory).with(
                               File.join('app', 'views', 'dashboard', 'test_models')
        )
      end
    end
  end

  describe '#create_controller_file' do
    let(:generator) do
      described_class.new(['test'], {}).tap do |g|
        g.destination_root = destination_root
        g.instance_variable_set(:@engine_scope_path, '')
        g.instance_variable_set(:@scope_path, 'test_models')
      end
    end

    before do
      allow(generator).to receive(:template)
    end

    it 'calls template with correct path' do
      generator.send(:create_controller_file)

      expect(generator).to have_received(:template).with(
                             'controllers/controller.rb.tt',
                             File.join('app', 'controllers', '', 'test_models_controller.rb')
      )
    end

    context 'with engine scope' do
      before do
        generator.instance_variable_set(:@engine_scope_path, 'admin')
      end

      it 'calls template with engine path' do
        generator.send(:create_controller_file)

        expect(generator).to have_received(:template).with(
                               'controllers/controller.rb.tt',
                               File.join('app', 'controllers', 'admin', 'test_models_controller.rb')
        )
      end
    end

    context 'with route scope' do
      before do
        generator.instance_variable_set(:@engine_scope_path, 'dashboard')
      end

      it 'calls template with scope path' do
        generator.send(:create_controller_file)

        expect(generator).to have_received(:template).with(
                               'controllers/controller.rb.tt',
                               File.join('app', 'controllers', 'dashboard', 'test_models_controller.rb')
        )
      end
    end
  end

  describe '#create_view_file' do
    let(:generator) do
      described_class.new(['test'], {}).tap do |g|
        g.destination_root = destination_root
        g.instance_variable_set(:@engine_scope_path, '')
        g.instance_variable_set(:@scope_path, 'test_models')
        g.instance_variable_set(:@form_fields, [])
      end
    end

    before do
      allow(generator).to receive(:generate_form_fields_html).and_return('<div>form fields</div>')
      allow(generator).to receive(:template)
    end

    it 'calls generate_form_fields_html' do
      generator.send(:create_view_file)

      expect(generator).to have_received(:generate_form_fields_html)
    end

    it 'assigns form_fields_html to instance variable' do
      generator.send(:create_view_file)

      expect(generator.instance_variable_get(:@form_fields_html)).to eq('<div>form fields</div>')
    end

    it 'calls template for all view files' do
      generator.send(:create_view_file)

      expect(generator).to have_received(:template).with(
                             'views/_form.html.erb.tt',
                             File.join('app', 'views', '', 'test_models', '_form.html.erb')
      )
      expect(generator).to have_received(:template).with(
                             'views/edit.html.erb.tt',
                             File.join('app', 'views', '', 'test_models', 'edit.html.erb')
      )
      expect(generator).to have_received(:template).with(
                             'views/index.html.erb.tt',
                             File.join('app', 'views', '', 'test_models', 'index.html.erb')
      )
      expect(generator).to have_received(:template).with(
                             'views/new.html.erb.tt',
                             File.join('app', 'views', '', 'test_models', 'new.html.erb')
      )
      expect(generator).to have_received(:template).with(
                             'views/show.html.erb.tt',
                             File.join('app', 'views', '', 'test_models', 'show.html.erb')
      )
    end

    context 'with engine scope' do
      before do
        generator.instance_variable_set(:@engine_scope_path, 'admin')
      end

      it 'calls template with engine path' do
        generator.send(:create_view_file)

        expect(generator).to have_received(:template).with(
                               'views/_form.html.erb.tt',
                               File.join('app', 'views', 'admin', 'test_models', '_form.html.erb')
        )
      end
    end
  end

  describe '#create_link_file' do
    let(:generator) do
      described_class.new(['test'], {}).tap do |g|
        g.destination_root = destination_root
        g.instance_variable_set(:@engine_scope_path, 'admin')
        g.instance_variable_set(:@scope_path, 'test_models')
      end
    end

    before do
      FileUtils.mkdir_p(File.join(destination_root, 'app', 'views', 'components', 'layouts'))
      FileUtils.mkdir_p(File.join(destination_root, 'app', 'views', 'components', 'menu'))
      FileUtils.mkdir_p(File.join(destination_root, 'config'))
      File.write(File.join(destination_root, 'config', 'routes.rb'), "Rails.application.routes.draw do\nend\n")

      allow(generator).to receive(:template)
      allow(generator).to receive(:inject_into_file)
      allow(generator).to receive(:insert_into_file)
      allow(generator).to receive(:namespace_exists?).and_return(false)
    end

    it 'calls template for menu link' do
      Dir.chdir(destination_root) do
        generator.send(:create_link_file)
      end

      expect(generator).to have_received(:template).with(
                             'views/components/menu/link.html.erb.tt',
                             File.join('app', 'views/components/menu', '_link_to_test_models.html.erb')
      )
    end

    context 'when sidebar exists' do
      before do
        sidebar_path = File.join(destination_root, 'app', 'views/components/layouts/_sidebar.html.erb')
        File.write(sidebar_path, "                <%# generate_link %>\n")
      end

      it 'injects link into sidebar' do
        Dir.chdir(destination_root) do
          generator.send(:create_link_file)
        end

        expect(generator).to have_received(:inject_into_file).with(
                               File.join('app', 'views/components/layouts/_sidebar.html.erb'),
                               anything,
                               before: "                <%# generate_link %>\n"
        )
      end
    end

    context 'when sidebar does not exist' do
      before do
        FileUtils.rm_f(File.join(destination_root, 'app', 'views/components/layouts/_sidebar.html.erb'))
      end

      it 'does not inject into sidebar' do
        Dir.chdir(destination_root) do
          generator.send(:create_link_file)
        end

        expect(generator).not_to have_received(:inject_into_file).with(
                                   File.join('app', 'views/components/layouts/_sidebar.html.erb'),
                                   anything,
                                   anything
        )
      end
    end

    context 'when link already exists' do
      before do
        link_path = File.join(destination_root, 'app', 'views/components/menu/_link_to_test_models.html.erb')
        FileUtils.touch(link_path)
      end

      it 'does not create template again' do
        Dir.chdir(destination_root) do
          generator.send(:create_link_file)
        end

        expect(generator).not_to have_received(:template)
      end
    end

    context 'when namespace does not exist' do
      before do
        allow(generator).to receive(:namespace_exists?).and_return(false)
        allow(generator).to receive(:routes_file_path).and_return(File.join(destination_root, 'config', 'routes.rb'))
        allow(generator).to receive(:options).and_return({})
        allow(generator).to receive(:engine_path).and_return(nil)
      end

      it 'injects routes at root level' do
        Dir.chdir(destination_root) do
          generator.send(:create_link_file)
        end

        expect(generator).to have_received(:inject_into_file).with(
                               File.join(destination_root, 'config', 'routes.rb'),
                               "  resources :test_models\n",
                               after: "Rails.application.routes.draw do\n"
        )
      end
    end

    context 'when namespace exists' do
      before do
        allow(generator).to receive(:namespace_exists?).and_return(true)
      end

      it 'does not create namespace again' do
        Dir.chdir(destination_root) do
          generator.send(:create_link_file)
        end

        expect(generator).not_to have_received(:insert_into_file)
      end
    end

    context 'with engine scope' do
      let(:generator_with_engine) do
        described_class.new(['test'], { engine: 'admin' }).tap do |g|
          g.destination_root = destination_root
          g.instance_variable_set(:@engine_scope_path, 'admin')
          g.instance_variable_set(:@scope_path, 'test_models')
        end
      end

      before do
        FileUtils.mkdir_p(File.join(destination_root, 'config'))
        File.write(File.join(destination_root, 'config', 'routes.rb'), "Admin::Engine.routes.draw do\nend\n")
        allow(generator_with_engine).to receive(:template)
        allow(generator_with_engine).to receive(:inject_into_file)
        allow(generator_with_engine).to receive(:routes_file_path).and_return(File.join(destination_root, 'config', 'routes.rb'))
        allow(generator_with_engine).to receive(:engine_path).and_return('engines/admin')
        allow(generator_with_engine).to receive(:options).and_return({ engine: 'admin' })
      end

      it 'injects resource routes' do
        Dir.chdir(destination_root) do
          generator_with_engine.send(:create_link_file)
        end

        expect(generator_with_engine).to have_received(:inject_into_file).with(
                               File.join(destination_root, 'config', 'routes.rb'),
                               "  resources :test_models\n",
                               after: "Admin::Engine.routes.draw do\n"
        )
      end
    end

    context 'without engine scope' do
      before do
        generator.instance_variable_set(:@engine_scope_path, '')
        allow(generator).to receive(:routes_file_path).and_return(File.join(destination_root, 'config', 'routes.rb'))
      end

      it 'injects resource routes at root level' do
        Dir.chdir(destination_root) do
          generator.send(:create_link_file)
        end

        expect(generator).to have_received(:inject_into_file).with(
                               anything,
                               anything,
                               after: "Rails.application.routes.draw do\n"
        )
      end
    end
  end

  describe '#running' do
    let(:generator) do
      described_class.new(['test'], {}).tap do |g|
        g.destination_root = destination_root
      end
    end

    before do
      allow(generator).to receive(:setup_variables)
      allow(generator).to receive(:create_root_folder)
      allow(generator).to receive(:create_controller_file)
      allow(generator).to receive(:create_spec_files)
      allow(generator).to receive(:create_view_file)
      allow(generator).to receive(:create_link_file)
    end

    it 'calls all methods in correct order' do
      generator.running

      expect(generator).to have_received(:setup_variables).ordered
      expect(generator).to have_received(:create_root_folder).ordered
      expect(generator).to have_received(:create_controller_file).ordered
      expect(generator).to have_received(:create_spec_files).ordered
      expect(generator).to have_received(:create_view_file).ordered
      expect(generator).to have_received(:create_link_file).ordered
    end

    it 'calls all required methods' do
      generator.running

      expect(generator).to have_received(:setup_variables)
      expect(generator).to have_received(:create_root_folder)
      expect(generator).to have_received(:create_controller_file)
      expect(generator).to have_received(:create_spec_files)
      expect(generator).to have_received(:create_view_file)
      expect(generator).to have_received(:create_link_file)
    end
  end

  describe '#available_engines' do
    let(:generator) { described_class.new(['test'], {}) }

    context 'when engines exist in engines/ directory' do
      before do
        allow(Dir).to receive(:exist?).and_call_original
        allow(Dir).to receive(:exist?).with('engines').and_return(true)
        allow(Dir).to receive(:exist?).with('components').and_return(false)
        allow(Dir).to receive(:exist?).with('gems').and_return(false)
        allow(Dir).to receive(:exist?).with('.').and_return(true)

        allow(Dir).to receive(:glob).with('engines/*').and_return(['engines/admin', 'engines/api'])
        allow(Dir).to receive(:glob).with('components/*').and_return([])
        allow(Dir).to receive(:glob).with('gems/*').and_return([])
        allow(Dir).to receive(:glob).with('./*').and_return([])

        allow(Dir).to receive(:exist?).with('engines/admin').and_return(true)
        allow(Dir).to receive(:exist?).with('engines/api').and_return(true)

        allow(File).to receive(:exist?).and_call_original
        allow(File).to receive(:exist?).with('engines/admin/admin.gemspec').and_return(true)
        allow(File).to receive(:exist?).with('engines/api/api.gemspec').and_return(true)
      end

      it 'returns engines from engines directory' do
        result = generator.send(:available_engines)

        expect(result).to include('admin')
        expect(result).to include('api')
      end
    end

    context 'when engines exist in components/ directory' do
      before do
        allow(Dir).to receive(:exist?).and_call_original
        allow(Dir).to receive(:exist?).with('engines').and_return(false)
        allow(Dir).to receive(:exist?).with('components').and_return(true)
        allow(Dir).to receive(:exist?).with('gems').and_return(false)
        allow(Dir).to receive(:exist?).with('.').and_return(false)

        allow(Dir).to receive(:glob).and_call_original
        allow(Dir).to receive(:glob).with('components/*').and_return(['components/core'])
        allow(Dir).to receive(:exist?).with('components/core').and_return(true)
        allow(File).to receive(:exist?).and_call_original
        allow(File).to receive(:exist?).with('components/core/core.gemspec').and_return(true)
      end

      it 'returns engines from components directory' do
        result = generator.send(:available_engines)

        expect(result).to include('core')
      end
    end

    context 'when engines exist in gems/ directory' do
      before do
        allow(Dir).to receive(:exist?).and_call_original
        allow(Dir).to receive(:exist?).with('engines').and_return(false)
        allow(Dir).to receive(:exist?).with('components').and_return(false)
        allow(Dir).to receive(:exist?).with('gems').and_return(true)
        allow(Dir).to receive(:exist?).with('.').and_return(false)

        allow(Dir).to receive(:glob).and_call_original
        allow(Dir).to receive(:glob).with('gems/*').and_return(['gems/shared'])
        allow(Dir).to receive(:exist?).with('gems/shared').and_return(true)
        allow(File).to receive(:exist?).and_call_original
        allow(File).to receive(:exist?).with('gems/shared/shared.gemspec').and_return(true)
      end

      it 'returns engines from gems directory' do
        result = generator.send(:available_engines)

        expect(result).to include('shared')
      end
    end

    context 'when engines exist in root directory' do
      before do
        allow(Dir).to receive(:exist?).and_call_original
        allow(Dir).to receive(:exist?).with('engines').and_return(false)
        allow(Dir).to receive(:exist?).with('components').and_return(false)
        allow(Dir).to receive(:exist?).with('gems').and_return(false)
        allow(Dir).to receive(:exist?).with('.').and_return(true)

        allow(Dir).to receive(:glob).with('./*').and_return(['./root_engine'])
        allow(Dir).to receive(:exist?).with('./root_engine').and_return(true)
        allow(File).to receive(:exist?).with('./root_engine/root_engine.gemspec').and_return(true)
      end

      it 'returns engines from root directory' do
        result = generator.send(:available_engines)

        expect(result).to include('root_engine')
      end
    end

    context 'when duplicate engines exist' do
      before do
        allow(Dir).to receive(:exist?).and_call_original
        allow(Dir).to receive(:exist?).with('engines').and_return(true)
        allow(Dir).to receive(:exist?).with('components').and_return(true)
        allow(Dir).to receive(:exist?).with('gems').and_return(false)
        allow(Dir).to receive(:exist?).with('.').and_return(false)

        allow(Dir).to receive(:glob).and_call_original
        allow(Dir).to receive(:glob).with('engines/*').and_return(['engines/admin'])
        allow(Dir).to receive(:glob).with('components/*').and_return(['components/admin'])

        allow(Dir).to receive(:exist?).with('engines/admin').and_return(true)
        allow(Dir).to receive(:exist?).with('components/admin').and_return(true)

        allow(File).to receive(:exist?).and_call_original
        allow(File).to receive(:exist?).with('engines/admin/admin.gemspec').and_return(true)
        allow(File).to receive(:exist?).with('components/admin/admin.gemspec').and_return(true)
      end

      it 'returns unique engines' do
        result = generator.send(:available_engines)

        expect(result.count('admin')).to eq(1)
      end
    end

    context 'when no engines exist' do
      before do
        allow(Dir).to receive(:exist?).and_return(false)
      end

      it 'returns empty array' do
        result = generator.send(:available_engines)

        expect(result).to eq([])
      end
    end
  end
end
