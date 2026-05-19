require "rails/generators/base"

module Backstage
  module Generators
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path("templates", __dir__)

      def copy_config
        copy_file "backstage.yml", "config/backstage.yml"
      end

      def create_initializer
        copy_file "backstage.rb", "config/initializers/backstage.rb"
      end

      def copy_skill
        empty_directory ".claude/skills/backstage-install"
        copy_file "SKILL.md", ".claude/skills/backstage-install/SKILL.md"
      end

      def mount_engine
        route 'mount Backstage::Engine, at: "/admin"'
      end

      def print_instructions
        say "\nBackstage installed!", :green
        say "  1. Edit config/backstage.yml to list your models"
        say "  2. Wire up current_user in config/initializers/backstage.rb"
        say "  3. Visit /admin"
        say "\n  Tip: run /backstage-install in Claude Code for a guided setup walkthrough"
        say "       (skill copied to .claude/skills/backstage-install/SKILL.md)\n"
      end
    end
  end
end
