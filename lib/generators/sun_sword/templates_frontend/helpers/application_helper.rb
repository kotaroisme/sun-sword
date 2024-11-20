module ApplicationHelper
  def flash_type(flash)
    flash.map { |type, msg| type }[0]
  end
end
