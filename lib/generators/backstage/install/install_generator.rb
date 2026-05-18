require "rails/generators/base"

module Backstage
  module Generators
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path("templates", __dir__)

      def copy_config
        copy_file "backstage.yml", "config/backstage.yml"
      end

      def mount_engine
        route 'mount Backstage::Engine, at: "/admin"'
      end

      def print_instructions
        say "\nBackstage installed!", :green
        say "  1. Edit config/backstage.yml to list your models"
        say "  2. Add current_user to your ApplicationController"
        say "  3. Visit /admin\n"
      end
    end
  end
end
