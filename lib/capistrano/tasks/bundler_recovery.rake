# frozen_string_literal: true

namespace :bundler do
  desc "Clear a corrupted shared bundle when bundle check reports broken native extensions"
  task :recover_shared_bundle do
    on fetch(:bundle_servers) do
      within release_path do
        with fetch(:bundle_env_variables) do
          check_output = capture(
            :bash,
            "-lc",
            <<~BASH
              set +e
              output="$(bundle check 2>&1)"
              status=$?
              printf '%s\n__BUNDLE_CHECK_STATUS__=%s\n' "$output" "$status"
            BASH
          )

          broken_extensions = check_output.include?("because its extensions are not built")
          missing_gems = check_output.include?("Bundler::GemNotFound")

          next unless broken_extensions || missing_gems

          warn "Bundler reported a corrupted shared bundle. Removing #{fetch(:bundle_path)} before reinstalling gems."
          execute :rm, "-rf", fetch(:bundle_path)
        end
      end
    end
  end
end

before "bundler:install", "bundler:recover_shared_bundle"
