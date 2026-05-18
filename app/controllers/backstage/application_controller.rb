module Backstage
  class ApplicationController < ActionController::Base
    layout "backstage/backstage"
    helper_method :nav_resources

    before_action :verify_admin!

    private

    def verify_admin!
      method = Backstage.configuration.admin_user_method
      unless current_user&.public_send(method)
        redirect_to Backstage.configuration.redirect_on_failure
      end
    end

    def nav_resources
      Backstage.registry.all_resources
    end
  end
end
