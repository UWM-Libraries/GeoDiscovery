# frozen_string_literal: true

class UwmHeaderComponent < Geoblacklight::HeaderComponent
  def before_render
    with_top_bar(component: UwmTopNavbarComponent) unless top_bar
    super
  end
end
