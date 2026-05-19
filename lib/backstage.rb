require "backstage/version"
require "backstage/configuration"
require "backstage/field"
require "backstage/association_config"
require "backstage/resource_config"
require "backstage/auto_discovery"
require "backstage/dashboard_config"
require "backstage/sidebar_config"
require "backstage/registry"
require "backstage/engine"

module Backstage
  class << self
    attr_accessor :configuration, :registry

    def load_configuration!(root)
      path = File.join(root, "config", "backstage.yml")
      hash = File.exist?(path) ? YAML.safe_load_file(path) || {} : {}
      self.configuration = Configuration.new(hash)

      self.registry = Registry.new
      configuration.model_names.each do |name|
        begin
          model_class = name.constantize
        rescue NameError
          raise ConfigurationError, "config/backstage.yml: unknown model '#{name}'"
        end
        begin
          registry.register(name, AutoDiscovery.build(model_class))
        rescue ActiveRecord::StatementInvalid => e
          warn "Backstage: skipping #{name} — #{e.message}"
          next
        end
      end

      load_dsl_files!(root)

      configuration.dashboard_configs.each do |hash|
        registry.register_dashboard(DashboardConfig.new(hash))
      end

      configuration
    end

    def resource(model_name)
      name = model_name.to_s
      config = registry.resource_for(name)
      yield config if block_given?
    rescue KeyError
      raise ConfigurationError, "config/backstage/*.rb: no registered model '#{name}'"
    end

    private

    def load_dsl_files!(root)
      dir = File.join(root, "config", "backstage")
      return unless File.directory?(dir)
      Dir.glob(File.join(dir, "*.rb")).sort.each { |f| load f }
    end
  end
end
