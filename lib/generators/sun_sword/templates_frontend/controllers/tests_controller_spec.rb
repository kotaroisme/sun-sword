# frozen_string_literal: true

RSpec.describe TestsController, type: :controller do
  routes { Web::Engine.routes }
  describe '#stimulus' do
    it 'renders the stimulus template' do
      get :stimulus

      expect(response).to render_template(:stimulus)
    end
  end

  describe '#turbo_drive' do
    it 'sets the timestamp' do
      get :turbo_drive

      expect(assigns(:timestamp)).to be_a(Time)
    end

    it 'renders the turbo_drive template' do
      get :turbo_drive

      expect(response).to render_template(:turbo_drive)
    end
  end

  describe '#turbo_frame' do
    it 'renders the turbo_frame template' do
      get :turbo_frame

      expect(response).to render_template(:turbo_frame)
    end
  end

  describe '#frame_content' do
    it 'renders turbo_stream response' do
      get :frame_content

      expect(response).to have_http_status(:success)
      expect(response.content_type).to include('text/vnd.turbo-stream.html')
    end
  end

  describe '#update_content' do
    it 'sets the timestamp' do
      post :update_content, format: :turbo_stream
      expect(assigns(:timestamp)).to be_a(Time)
    end

    it 'responds with turbo_stream format' do
      post :update_content, format: :turbo_stream
      expect(response).to have_http_status(:success)
      expect(response.content_type).to include('text/vnd.turbo-stream.html')
    end
  end

  describe '#set_layouts' do
    it 'returns application layout' do
      expect(controller.send(:set_layouts)).to eq('application')
    end
  end
end
