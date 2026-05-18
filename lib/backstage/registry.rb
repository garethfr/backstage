module Backstage
  class Registry
    def initialize
      @resources = {}
      @dashboards = {}
    end

    def register(model_name, resource_config)
      @resources[model_name] = resource_config
    end

    def resource_for(model_name)
      @resources.fetch(model_name) { raise KeyError, "Backstage: no resource registered for '#{model_name}'" }
    end

    def all_resources
      @resources.values
    end

    def register_dashboard(dashboard_config)
      @dashboards[dashboard_config.name] = dashboard_config
    end

    def dashboard_for(name)
      @dashboards.fetch(name) { raise KeyError, "Backstage: no dashboard registered for '#{name}'" }
    end

    def all_dashboards
      @dashboards.values
    end
  end
end
