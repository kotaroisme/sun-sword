class TestsController < ApplicationController
  layout :set_layouts

  def stimulus
    # Test halaman untuk Stimulus
  end

  def turbo_drive
    @timestamp = Time.current
  end

  def turbo_frame
    # Test halaman untuk Turbo Frames
  end

  def frame_content
    # Render turbo frame content
    render turbo_stream: turbo_stream.replace(
                           request.headers['Turbo-Frame'] || 'lazy-content',
                           partial: 'tests/frame_content'
    )
  end

  def update_content
    @timestamp = Time.current

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.update('dynamic-content', partial: 'tests/updated_content'),
          turbo_stream.append('log', partial: 'tests/log_entry', locals: { timestamp: @timestamp })
        ]
      end
    end
  end
end
