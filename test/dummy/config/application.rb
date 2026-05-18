require_relative "boot"

require "rails"
require "active_record/railtie"
require "action_controller/railtie"
require "action_view/railtie"
require "rails/test_unit/railtie"

Bundler.require(*Rails.groups)

module Dummy
  class Application < Rails::Application
    config.root = File.expand_path("..", __dir__)
    config.load_defaults 8.0
    config.eager_load = false

    # With in-memory SQLite the DB starts empty. Load the schema before the
    # engine's to_prepare callback fires (which calls AutoDiscovery, which
    # needs the tables to already exist).
    initializer :load_test_schema,
      after: "active_record.initialize_database",
      before: :run_prepare_callbacks do
      ActiveRecord::Schema.verbose = false
      load config.root.join("db", "schema.rb")
    end
  end
end
