require "yaml"

module Backstage
  class ConfigurationError < StandardError; end

  class Configuration
    attr_reader :admin_user_method, :redirect_on_failure, :per_page,
      :model_names, :dashboard_configs

    def initialize(hash)
      @admin_user_method = (hash["admin_user_method"] || "is_admin?").to_sym
      @redirect_on_failure = hash["redirect_on_failure"] || "/"
      @per_page = hash["per_page"] || 25
      @model_names = hash["models"] || []
      @dashboard_configs = hash["dashboards"] || []

      validate!
    end

    private

    def validate!
      unless @model_names.is_a?(Array)
        raise ConfigurationError, "config/backstage.yml: 'models' must be a list, got #{@model_names.inspect}"
      end
      unless @per_page.is_a?(Integer)
        raise ConfigurationError, "config/backstage.yml: 'per_page' must be an integer, got #{@per_page.inspect}"
      end
    end
  end
end
