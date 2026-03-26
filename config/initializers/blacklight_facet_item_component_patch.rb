# frozen_string_literal: true

Rails.application.config.to_prepare do
  Blacklight::FacetItemComponent.class_eval do
    def render_selected_facet_value
      tag.span(class: "facet-label") do
        tag.span(label, class: "selected") +
          link_to(
            href,
            class: "remove",
            rel: "nofollow",
            aria: {label: helpers.t(:"blacklight.search.facets.selected.remove")}
          ) do
            tag.span("✖", class: "remove-icon", aria: {hidden: true})
          end
      end + render_facet_count(classes: ["selected"])
    end
  end
end
