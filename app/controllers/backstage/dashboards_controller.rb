module Backstage
  class DashboardsController < ApplicationController
    def show
      @dashboard = Backstage.registry.dashboard_for(params[:name])
      @resource_config = @dashboard.resource_config
      per_page = Backstage.configuration.per_page
      @page = (params[:page] || 1).to_i
      scope = @resource_config.model_class.where(@dashboard.scope)
      @total_pages = [(scope.count.to_f / per_page).ceil, 1].max
      @records = scope.offset((@page - 1) * per_page).limit(per_page)
    rescue KeyError
      render plain: "Not Found", status: :not_found
    end
  end
end
