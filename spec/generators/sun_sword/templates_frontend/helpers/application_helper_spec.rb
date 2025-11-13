# frozen_string_literal: true

require 'spec_helper'
require 'generators/sun_sword/templates_frontend/helpers/application_helper'

RSpec.describe ApplicationHelper do
  # Create a test class that includes the helper module
  let(:test_class) do
    Class.new do
      include ApplicationHelper

      def link_to(path, options = {}, &block)
        # Mock implementation for testing
      end
    end
  end

  let(:helper_instance) { test_class.new }

  describe '#post_to' do
    let(:path) { '/test/path' }
    let(:options) { { class: 'btn' } }

    before do
      allow(helper_instance).to receive(:link_to)
    end

    it 'calls link_to with turbo_method :post' do
      helper_instance.post_to(path, options)

      expect(helper_instance).to have_received(:link_to).with(
                                   path,
                                   hash_including(data: hash_including(turbo_method: :post))
      )
    end

    it 'merges options with deep_merge' do
      helper_instance.post_to(path, options)

      expect(helper_instance).to have_received(:link_to).with(
                                   path,
                                   hash_including(class: 'btn', data: hash_including(turbo_method: :post))
      )
    end

    it 'accepts block parameter' do
      block_called = false
      block = proc { block_called = true }

      allow(helper_instance).to receive(:link_to).and_yield

      helper_instance.post_to(path, options, &block)

      expect(helper_instance).to have_received(:link_to)
    end
  end

  describe '#delete_to' do
    let(:path) { '/test/path' }
    let(:options) { { class: 'btn' } }

    before do
      allow(helper_instance).to receive(:link_to)
    end

    it 'calls link_to with turbo_method :delete' do
      helper_instance.delete_to(path, options)

      expect(helper_instance).to have_received(:link_to).with(
                                   path,
                                   hash_including(data: hash_including(turbo_method: :delete))
      )
    end

    it 'merges options with deep_merge' do
      helper_instance.delete_to(path, options)

      expect(helper_instance).to have_received(:link_to).with(
                                   path,
                                   hash_including(class: 'btn', data: hash_including(turbo_method: :delete))
      )
    end

    it 'accepts block parameter' do
      allow(helper_instance).to receive(:link_to).and_yield

      helper_instance.delete_to(path, options) { 'Delete' }

      expect(helper_instance).to have_received(:link_to)
    end
  end

  describe '#patch_to' do
    let(:path) { '/test/path' }
    let(:options) { { class: 'btn' } }

    before do
      allow(helper_instance).to receive(:link_to)
    end

    it 'calls link_to with turbo_method :patch' do
      helper_instance.patch_to(path, options)

      expect(helper_instance).to have_received(:link_to).with(
                                   path,
                                   hash_including(data: hash_including(turbo_method: :patch))
      )
    end

    it 'merges options with deep_merge' do
      helper_instance.patch_to(path, options)

      expect(helper_instance).to have_received(:link_to).with(
                                   path,
                                   hash_including(class: 'btn', data: hash_including(turbo_method: :patch))
      )
    end

    it 'accepts block parameter' do
      allow(helper_instance).to receive(:link_to).and_yield

      helper_instance.patch_to(path, options) { 'Update' }

      expect(helper_instance).to have_received(:link_to)
    end
  end

  describe '#flash_type' do
    context 'with flash hash containing one key' do
      let(:flash) { { notice: 'Success message' } }

      it 'returns the first key' do
        result = helper_instance.flash_type(flash)
        expect(result).to eq(:notice)
      end
    end

    context 'with multiple flash keys' do
      let(:flash) { { notice: 'Success', alert: 'Error' } }

      it 'returns the first key' do
        result = helper_instance.flash_type(flash)
        expect(result).to eq(:notice)
      end
    end

    context 'with empty flash hash' do
      let(:flash) { {} }

      it 'returns nil' do
        result = helper_instance.flash_type(flash)
        expect(result).to be_nil
      end
    end
  end

  describe '#truncate_html' do
    let(:html) { '<p>This is a long HTML string</p>' }
    let(:html_string) { instance_double('TruncateHtml::HtmlString') }
    let(:truncator) { instance_double('TruncateHtml::HtmlTruncator') }

    before do
      stub_const('TruncateHtml::HtmlString', Class.new)
      stub_const('TruncateHtml::HtmlTruncator', Class.new)

      allow(TruncateHtml::HtmlString).to receive(:new).with(html).and_return(html_string)
      allow(TruncateHtml::HtmlTruncator).to receive(:new).with(html_string, {}).and_return(truncator)
      allow(truncator).to receive(:truncate).and_return('<p>This is...</p>')
    end

    it 'truncates HTML string' do
      result = helper_instance.truncate_html(html)

      expect(TruncateHtml::HtmlString).to have_received(:new).with(html)
      expect(TruncateHtml::HtmlTruncator).to have_received(:new).with(html_string, {})
      expect(truncator).to have_received(:truncate)
      expect(result).to eq('<p>This is...</p>')
    end

    it 'passes options to truncator' do
      opts = { length: 10, omission: '...' }
      allow(TruncateHtml::HtmlTruncator).to receive(:new).with(html_string, opts).and_return(truncator)

      helper_instance.truncate_html(html, opts)

      expect(TruncateHtml::HtmlTruncator).to have_received(:new).with(html_string, opts)
    end

    context 'with nil input' do
      it 'handles nil gracefully' do
        allow(TruncateHtml::HtmlString).to receive(:new).with(nil).and_return(html_string)

        expect { helper_instance.truncate_html(nil) }.not_to raise_error
      end
    end

    context 'with empty string' do
      it 'handles empty string' do
        empty_html_string = instance_double('TruncateHtml::HtmlString')
        allow(TruncateHtml::HtmlString).to receive(:new).with('').and_return(empty_html_string)
        allow(TruncateHtml::HtmlTruncator).to receive(:new).with(empty_html_string, {}).and_return(truncator)
        allow(truncator).to receive(:truncate).and_return('')

        result = helper_instance.truncate_html('')

        expect(result).to eq('')
      end
    end
  end
end
