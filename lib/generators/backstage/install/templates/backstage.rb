Rails.application.config.to_prepare do
  Backstage::ApplicationController.class_eval do
    def current_user
      # TODO: replace with your actual current_user lookup
      # Devise example:   warden.authenticate(scope: :user)
      # Session example:  User.find_by(id: session[:user_id])
      # Current example:  Current.user
      nil
    end
  end
end
