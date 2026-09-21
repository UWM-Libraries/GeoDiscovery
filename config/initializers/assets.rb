# frozen_string_literal: true

# Add local vendor images to the Propshaft load path.
Rails.application.config.assets.paths << Rails.root.join("vendor", "assets", "images")
