module Backstage
  class Engine < ::Rails::Engine
    isolate_namespace Backstage

    initializer "backstage.configuration" do |app|
      app.config.to_prepare do
        Backstage.load_configuration!(app.root)
      end
    end
  end
end
