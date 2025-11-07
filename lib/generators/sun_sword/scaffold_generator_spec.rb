# frozen_string_literal: true

require 'fileutils'
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
end
