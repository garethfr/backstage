ENV["RAILS_ENV"] ||= "test"
require_relative "dummy/config/environment"
require "rails/test_help"

ActiveRecord::Schema.verbose = false
load File.expand_path("dummy/db/schema.rb", __dir__)

def set_current_user(user)
  Thread.current[:backstage_current_user] = user
end

def mock_user(is_admin:)
  u = Object.new
  u.define_singleton_method(:is_admin?) { is_admin }
  u
end
