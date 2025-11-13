# frozen_string_literal: true

RSpec.describe SunSword do
  describe 'VERSION' do
    it 'has a version number' do
      expect(SunSword::VERSION).not_to be nil
    end

    it 'follows semantic versioning format' do
      # Semantic versioning: MAJOR.MINOR.PATCH
      version_pattern = /\A\d+\.\d+\.\d+(\.[a-zA-Z0-9]+)?\z/
      expect(SunSword::VERSION).to match(version_pattern)
    end

    it 'is a public constant' do
      expect(SunSword.const_defined?(:VERSION, false)).to be true
    end
  end

  describe 'scope_owner_column setting' do
    it 'defines scope_owner_column getter' do
      expect(SunSword).to respond_to(:scope_owner_column)
    end

    it 'defines scope_owner_column setter' do
      expect(SunSword).to respond_to(:scope_owner_column=)
    end

    it 'has default value of empty string' do
      expect(SunSword.scope_owner_column).to eq('')
    end

    it 'allows setting and getting values' do
      original_value = SunSword.scope_owner_column

      SunSword.scope_owner_column = 'user_id'
      expect(SunSword.scope_owner_column).to eq('user_id')

      # Restore original value
      SunSword.scope_owner_column = original_value
    end

    it 'integrates with Configuration module' do
      expect(SunSword.class.included_modules).to include(SunSword::Configuration)
    end
  end
end
