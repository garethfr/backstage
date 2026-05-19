module Backstage
  class Engine < ::Rails::Engine
    isolate_namespace Backstage

    initializer "backstage.configuration" do |app|
      app.config.to_prepare do
        Backstage.load_configuration!(app.root)
      rescue ActiveRecord::ConnectionNotEstablished, ActiveRecord::NoDatabaseError => e
        Rails.logger.warn "Backstage: skipping configuration — no database connection (#{e.class})"
      end
    end
  end
end
