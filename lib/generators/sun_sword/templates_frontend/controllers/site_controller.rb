class SiteController < ApplicationController
  layout :set_layouts
  def stimulus
    @comment = '- WELCOME -'
  end

  def jadi_a
    @comment = 'Kotaro'
    render partial: 'site/comment'
  end

  def jadi_b
    @comment = 'Minami'
    render partial: 'site/comment'
  end
end
