require "test_helper"
require "rails/generators/test_case"
require "generators/backstage/install/install_generator"

class InstallGeneratorTest < Rails::Generators::TestCase
  tests Backstage::Generators::InstallGenerator
  destination File.expand_path("../../tmp/generator_test", __dir__)

  setup { prepare_destination }

  test "creates backstage.yml" do
    run_generator
    assert_file "config/backstage.yml"
  end

  test "backstage.yml contains models key" do
    run_generator
    assert_file "config/backstage.yml" do |content|
      assert_match "models:", content
    end
  end

  test "copies Claude skill file" do
    run_generator
    assert_file ".claude/skills/backstage-install.md" do |content|
      assert_match "backstage-install", content
    end
  end

  test "appends mount to routes.rb" do
    FileUtils.mkdir_p(File.join(destination_root, "config"))
    File.write(File.join(destination_root, "config", "routes.rb"),
      "Rails.application.routes.draw do\nend\n")
    run_generator
    assert_file "config/routes.rb" do |content|
      assert_match "mount Backstage::Engine", content
    end
  end
end
