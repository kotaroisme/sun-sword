require 'fileutils'
require 'generators/sun_sword/scaffold_generator'
require 'rails_helper'

RSpec.describe SunSword::ScaffoldGenerator, type: :generator do
  let(:destination_root) { File.expand_path('../../../tmp/test_app', __dir__) }
  let(:structure_file) { 'test_structure.yaml' }

  before do
    FileUtils.mkdir_p(File.join(destination_root, 'db', 'structures'))
    File.write(File.join(destination_root, 'db', 'structures', "test_structure.yaml"), {
      'model'         => 'Campaign',
      'resource_name' => 'campaigns',
      'actor'         => 'user',
      'domains'       => {
        'action_list'        => { 'use_case' => { 'contract' => [] } },
        'action_fetch_by_id' => { 'use_case' => { 'contract' => [] } },
        'action_create'      => { 'use_case' => { 'contract' => [] } },
        'action_update'      => { 'use_case' => { 'contract' => [] } },
        'action_destroy'     => { 'use_case' => { 'contract' => [] } }
      },
      'controllers'   => { 'form_fields' => [] }
    }.to_yaml)

    # Mock model
    stub_const('Campaign', Class.new do
      def self.columns
        []
      end

      def self.columns_hash
        {}
      end

      def self.name
        'Campaign'
      end
    end)
  end

  after do
    FileUtils.rm_rf(destination_root)
  end

  it 'uses domain option for usecase prefix in controller' do
    generator = described_class.new(['test'], { domain: 'core' })
    generator.destination_root = destination_root

    Dir.chdir(destination_root) do
      generator.send(:setup_variables)
      generator.send(:create_controller_file)

      content = File.read(File.join(destination_root, 'app', 'controllers', 'campaigns_controller.rb'))
      expect(content).to include('use_case = Core::UseCases::Campaigns::UserListCampaign')
    end
  end

  it 'uses domain option for usecase prefix in controller spec' do
    generator = described_class.new(['test'], { domain: 'core' })
    generator.destination_root = destination_root

    Dir.chdir(destination_root) do
      generator.send(:setup_variables)
      generator.send(:create_spec_files)

      content = File.read(File.join(destination_root, 'app', 'controllers', 'campaigns_controller_spec.rb'))
      expect(content).to include('instance_double(Core::UseCases::Campaigns::UserListCampaign)')
      expect(content).not_to include('instance_double(Core::Core::UseCases::')
    end
  end

  it 'falls back to engine_structure if domain is not provided' do
    generator = described_class.new(['test'], { engine_structure: 'core' })
    generator.destination_root = destination_root

    Dir.chdir(destination_root) do
      generator.send(:setup_variables)
      generator.send(:create_controller_file)

      content = File.read(File.join(destination_root, 'app', 'controllers', 'campaigns_controller.rb'))
      expect(content).to include('use_case = Core::UseCases::Campaigns::UserListCampaign')
    end
  end
end
