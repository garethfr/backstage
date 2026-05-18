Rails.application.configure do
  config.enable_reloading = false
  config.eager_load = false
  config.cache_store = :null_store
  config.active_support.deprecation = :stderr
  config.action_controller.allow_forgery_protection = false
end
