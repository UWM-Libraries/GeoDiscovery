# ~/.codex/AGENTS.md

## Working agreements

- Whenever reasonable, reference available documentation:
  - AGSL GeoDiscovery Documentation site: https://uwm-libraries.github.io/GeoDiscovery-Documentation/
  - GeoBlacklight Documentation Site for 4.x: https://geoblacklight.org/4.x/docs/
  - GeoBlacklight Documentation Site for 5.x upgrade planning: https://geoblacklight.org/
  - Project Blacklight Wiki: https://github.com/projectblacklight/blacklight/wiki
  - Capistrano Documentation: https://capistranorb.com/
  - Passenger documentation (we use Ruby and Apache): https://www.phusionpassenger.com/docs/
  - NOID documentation (we use NOID for minting unique identifiers): https://metacpan.org/dist/Noid/view/noid
- GeoBlacklight 4.x is the current target for maintenance work. Do not assume GeoBlacklight 5.x behavior unless the task is explicitly about upgrade planning or migration.
- Local development depends on Ruby and Java. Solr is required for normal application behavior.
- Prefer the documented local startup task: `bundle exec rake uwm:server`.
- After modifying any Ruby file or Ruby-based config, run `bundle exec standardrb --fix`.
- After modifying application code, tests, database code, routes, initializers, or environment/configuration that could affect runtime behavior, run `RAILS_ENV=test bundle exec rake ci`.
- For documentation-only or clearly isolated non-runtime changes, skip the full test suite unless I explicitly ask you to test the app.
- If full verification is too expensive during iteration, run the narrowest relevant check first, then run broader verification before finishing when the change affects runtime behavior.
- Do not edit vendored, generated, or environment-specific files unless the task clearly requires it.
- Before changing deployment-related code or configuration, review the existing deployment setup and call out any operational risk.
- If a required verification step cannot run, say so clearly and explain why.
- If it's possible that errors are related to the production environment, consider that a possiblity and ask for follow up information from the server (e.g. logs, versions, locations, permissions, etc.)

## Repository-specific preferences

- This application is not a stock GeoBlacklight install. Prefer existing project patterns over generic Rails or GeoBlacklight advice. Before introducing a new approach, look for similar implementations in controllers, helpers, presenters, views, rake tasks, and initializers.
- Treat `config/settings.yml`, route constraints, initializers, and local controller overrides as authoritative for application behavior. Do not assume upstream defaults when local behavior is present.
- For search, facet, and item-display changes, review both Blacklight configuration and GeoBlacklight-specific overrides before proposing code changes.
- For metadata work, preserve Aardvark/OpenGeoMetadata expectations and validate field names, value shapes, and intent against the local schema and indexing conventions before changing mappings or document structure.
- Be cautious about changes that affect Solr field names, indexing pipelines, facet configuration, or document presenters; these often have cross-cutting effects in search results, show pages, downloads, and API responses.
- When working on thumbnails, images, IIIF, or Allmaps-related behavior, trace the full path from metadata fields to helper/presenter logic to rendered UI before changing implementation details.
- Common metadata and indexing workflows include GeoCombine harvest/index tasks and GeoBlacklight sidecar image harvest tasks. Prefer extending existing rake tasks and service objects over adding standalone scripts, especially for harvest, indexing, thumbnails, and metadata-maintenance workflows.
- When proposing a fix, call out whether it is a local customization, an upstream GeoBlacklight/Blacklight pattern, or a temporary workaround.
- For deployment-facing changes, note any assumptions about Apache, Passenger, Capistrano roles, shared paths, background jobs, Redis, and environment variables.
- For changes involving rate limiting, request blocking, or access behavior, inspect the local middleware and initializer configuration before describing expected responses.
- Preserve library-oriented clarity in code comments, documentation, and commit notes. Prefer explicit naming and brief explanation over clever abstractions.
- When editing documentation, favor operational usefulness: include the exact command to run, where in the app the behavior lives, and any AGSL-specific caveats.
- If a task touches upgrade planning, first identify local overrides and custom behavior in `app/`, `config/`, `lib/`, and JavaScript integration points, and separate “safe for current GeoBlacklight 4.x maintenance” recommendations from “candidate for GeoBlacklight 5.x migration” recommendations.
- Do not remove or simplify AGSL-specific behavior merely because upstream GeoBlacklight handles the same area differently; first confirm the local reason for the customization.
- When unsure why a customization exists, inspect git history and nearby code before replacing it with a cleaner-looking upstream-style implementation.
- Prefer small, reviewable changes that preserve current behavior unless the task explicitly asks for refactoring.
- For view-layer changes, check for existing partials, helpers, and Stimulus/JavaScript hooks before restructuring templates.
- For indexing or metadata normalization changes, document sample input and expected Solr output in notes or the final summary when possible.
- When adding configuration, prefer patterns already used in the repository so deployment and local setup remain predictable.
- Flag any change that may require reindexing, cache clearing, restart, or redeploy.
- Flag any change that may impact WCAG compliance or web accessibility
