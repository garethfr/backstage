Rails.application.config.to_prepare do
  Backstage::ApplicationController.class_eval do
    def current_user
      Thread.current[:backstage_current_user] || session_admin_user
    end

    private

    def session_admin_user
      return nil unless respond_to?(:session) && session[:test_is_admin]
      u = Object.new
      u.define_singleton_method(:is_admin?) { true }
      u
    end
  end
end
