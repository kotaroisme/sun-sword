class Dashboard::SiteController < ApplicationController
  layout :set_layouts
  def index
    render 'site/stimulus'
  end
end
