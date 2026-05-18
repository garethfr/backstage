Rails.application.routes.draw do
  if Rails.env.test?
    get "test_login" => ->(env) {
      ActionDispatch::Request.new(env).session[:test_is_admin] = true
      [200, {"Content-Type" => "text/html"}, ["OK"]]
    }
  end

  mount Backstage::Engine, at: "/admin"
end
