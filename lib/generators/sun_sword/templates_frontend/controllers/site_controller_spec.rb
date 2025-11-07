# frozen_string_literal: true

RSpec.describe SiteController, type: :controller do
  describe '#stimulus' do
    it 'sets the welcome comment' do
      get :stimulus

      expect(assigns(:comment)).to eq('- WELCOME -')
    end

    it 'renders the stimulus template' do
      get :stimulus

      expect(response).to render_template(:stimulus)
    end
  end

  describe '#jadi_a' do
    it 'sets the comment to Kotaro' do
      get :jadi_a

      expect(assigns(:comment)).to eq('Kotaro')
    end

    it 'renders the site/comment partial' do
      get :jadi_a

      expect(response).to render_template(partial: 'site/comment')
    end
  end

  describe '#jadi_b' do
    it 'sets the comment to Minami' do
      get :jadi_b

      expect(assigns(:comment)).to eq('Minami')
    end

    it 'renders the site/comment partial' do
      get :jadi_b

      expect(response).to render_template(partial: 'site/comment')
    end
  end

  describe '#set_layouts' do
    it 'returns application layout' do
      expect(controller.send(:set_layouts)).to eq('application')
    end
  end
end
