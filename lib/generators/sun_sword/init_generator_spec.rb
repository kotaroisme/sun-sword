# frozen_string_literal: true

require 'fileutils'
require 'generators/sun_sword/init_generator'

RSpec.describe SunSword::InitGenerator, type: :generator do
  include FileUtils

  let(:destination_root) { File.expand_path('../tmp', __dir__) }

  before do
    FileUtils.mkdir_p(destination_root) unless Dir.exist?(destination_root)
  end

  after do
    FileUtils.rm_rf(destination_root) if Dir.exist?(destination_root)
  end

  describe 'source root' do
    it 'has the correct source root' do
      source_path = File.expand_path('templates_init', File.dirname(__FILE__))
      expect(described_class.source_root).to eq(source_path)
    end
  end

  describe '#setup_configuration' do
    it 'calls copy_initializer with sun_sword' do
      generator = described_class.new([], {})
      generator.destination_root = destination_root

      allow(generator).to receive(:copy_initializer)

      generator.setup_configuration

      expect(generator).to have_received(:copy_initializer).with('sun_sword')
    end
  end

  describe '#copy_initializer' do
    let(:generator) do
      described_class.new([], {}).tap do |g|
        g.destination_root = destination_root
      end
    end

    it 'copies initializer template to correct location' do
      allow(generator).to receive(:template)

      generator.send(:copy_initializer, 'sun_sword')

      expect(generator).to have_received(:template).with(
                             'config/initializers/sun_sword.rb',
                             'config/initializers/sun_sword.rb'
      )
    end

    it 'works with different file names' do
      allow(generator).to receive(:template)

      generator.send(:copy_initializer, 'custom_config')

      expect(generator).to have_received(:template).with(
                             'config/initializers/custom_config.rb',
                             'config/initializers/custom_config.rb'
      )
    end
  end

  describe 'integration test' do
    it 'can be instantiated' do
      generator = described_class.new([], {})
      expect(generator).to be_a(described_class)
    end

    it 'runs setup_configuration method' do
      generator = described_class.new([], {})
      generator.destination_root = destination_root

      expect(generator).to respond_to(:setup_configuration)
    end
  end
end
