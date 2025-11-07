# frozen_string_literal: true

RSpec.describe SunSword::Configuration do
  let(:test_class) do
    Class.new do
      extend SunSword::Configuration
    end
  end

  describe '.setup' do
    it 'yields self to the block' do
      yielded_object = nil
      test_class.setup do |config|
        yielded_object = config
      end

      expect(yielded_object).to eq(test_class)
    end

    it 'allows configuration through the block' do
      test_class.setup do |config|
        config.define_setting(:test_setting, 'default_value')
      end

      expect(test_class.test_setting).to eq('default_value')
    end
  end

  describe '.define_setting' do
    it 'defines a getter method for the setting' do
      test_class.define_setting(:api_key)

      expect(test_class).to respond_to(:api_key)
    end

    it 'defines a setter method for the setting' do
      test_class.define_setting(:api_key)

      expect(test_class).to respond_to(:api_key=)
    end

    it 'sets default value when provided' do
      test_class.define_setting(:timeout, 30)

      expect(test_class.timeout).to eq(30)
    end

    it 'allows setting and getting values' do
      test_class.define_setting(:database_url)

      test_class.database_url = 'postgresql://localhost/test'

      expect(test_class.database_url).to eq('postgresql://localhost/test')
    end

    it 'maintains separate values for different settings' do
      test_class.define_setting(:host, 'localhost')
      test_class.define_setting(:port, 3000)

      expect(test_class.host).to eq('localhost')
      expect(test_class.port).to eq(3000)
    end
  end

  describe 'settings isolation' do
    it 'maintains separate settings between different classes' do
      class1 = Class.new { extend SunSword::Configuration }
      class2 = Class.new { extend SunSword::Configuration }

      class1.define_setting(:shared_setting, 'class1_value')
      class2.define_setting(:shared_setting, 'class2_value')

      expect(class1.shared_setting).to eq('class1_value')
      expect(class2.shared_setting).to eq('class2_value')
    end
  end
end
