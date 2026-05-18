Backstage::Engine.routes.draw do
  root to: "home#index"

  get "dashboards/:name", to: "dashboards#show", as: :dashboard

  scope ":resource" do
    get "/", to: "resources#index", as: :resources
    get "/new", to: "resources#new", as: :new_resource
    post "/", to: "resources#create"
    get "/:id/edit", to: "resources#edit", as: :edit_resource
    patch "/:id", to: "resources#update", as: :resource
    delete "/:id", to: "resources#destroy"
    post "/:id/:action_name", to: "actions#create", as: :resource_action
  end
end
