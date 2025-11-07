# frozen_string_literal: true

RSpec.describe ApplicationHelper, type: :helper do
  describe '#flash_type' do
    it 'returns the first flash type from a flash hash' do
      flash = { 'notice' => 'Welcome!', 'error' => 'Something went wrong' }

      expect(helper.flash_type(flash)).to eq('notice')
    end

    it 'returns nil for empty flash' do
      flash = {}

      expect(helper.flash_type(flash)).to be_nil
    end

    it 'returns the only flash type' do
      flash = { 'success' => 'Operation successful' }

      expect(helper.flash_type(flash)).to eq('success')
    end

    it 'returns the first type when multiple flashes exist' do
      flash = { 'alert' => 'Warning', 'notice' => 'Info', 'error' => 'Error' }

      # Hash order is preserved in Ruby 1.9+, so first key should be 'alert'
      expect(helper.flash_type(flash)).to eq('alert')
    end
  end
end
