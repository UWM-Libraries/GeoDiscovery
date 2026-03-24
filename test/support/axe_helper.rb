# frozen_string_literal: true

module AxeHelper
  AXE_SOURCE = Rails.root.join("node_modules", "axe-core", "axe.min.js").freeze
  AXE_RULESET = {
    runOnly: {
      type: "tag",
      values: %w[wcag2a wcag2aa wcag21aa]
    }
  }.freeze

  def assert_no_axe_violations
    page.execute_script(File.read(AXE_SOURCE))

    results = page.evaluate_async_script(<<~JS)
      const done = arguments[arguments.length - 1];

      axe.run(document, #{AXE_RULESET.to_json}, (error, results) => {
        if (error) {
          done({ error: error.toString() });
          return;
        }

        done(results);
      });
    JS

    assert_nil results["error"], results["error"]
    assert_empty results["violations"], axe_violation_message(results["violations"])
  end

  private

  def axe_violation_message(violations)
    violations.map do |violation|
      impacted_nodes = violation["nodes"].map do |node|
        target = Array(node["target"]).join(" ")
        summary = node["failureSummary"]
        "#{target}\n#{summary}"
      end.join("\n\n")

      <<~TEXT
        #{violation["id"]}: #{violation["help"]}
        #{violation["helpUrl"]}
        #{impacted_nodes}
      TEXT
    end.join("\n")
  end
end
