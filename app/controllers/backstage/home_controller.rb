module Backstage
  class HomeController < ApplicationController
    def index
      @resources = Backstage.registry.all_resources.map do |config|
        {config: config, count: config.model_class.count}
      end
      @dashboards = Backstage.registry.all_dashboards.map do |dash|
        rc = dash.resource_config
        count = rc.model_class.where(dash.scope).count
        {dashboard: dash, count: count}
      end
    end
  end
end
