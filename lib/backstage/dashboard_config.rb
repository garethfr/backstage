module Backstage
  class DashboardConfig
    attr_reader :name, :model_name, :scope

    def initialize(hash)
      @name = hash["name"] or raise ArgumentError, "Dashboard config missing 'name'"
      @model_name = hash["model"] or raise ArgumentError, "Dashboard config missing 'model'"
      @scope = hash["scope"] || {}
    end

    def resource_config
      Backstage.registry.resource_for(model_name)
    end
  end
end
