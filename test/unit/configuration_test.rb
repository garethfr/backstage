require "test_helper"
require "tmpdir"
require "fileutils"

class ConfigurationTest < ActiveSupport::TestCase
  setup do
    @orig_configuration = Backstage.configuration
    @orig_registry = Backstage.registry
  end

  teardown do
    Backstage.configuration = @orig_configuration
    Backstage.registry = @orig_registry
  end

  test "defaults when built from empty hash" do
    config = Backstage::Configuration.new({})
    assert_equal :is_admin?, config.admin_user_method
    assert_equal "/", config.redirect_on_failure
    assert_equal 25, config.per_page
    assert_equal [], config.model_names
    assert_equal [], config.dashboard_configs
  end

  test "parses admin_user_method as a symbol" do
    config = Backstage::Configuration.new("admin_user_method" => "is_staff?")
    assert_equal :is_staff?, config.admin_user_method
  end

  test "parses redirect_on_failure" do
    config = Backstage::Configuration.new("redirect_on_failure" => "/login")
    assert_equal "/login", config.redirect_on_failure
  end

  test "parses per_page" do
    config = Backstage::Configuration.new("per_page" => 50)
    assert_equal 50, config.per_page
  end

  test "parses model_names" do
    config = Backstage::Configuration.new("models" => ["Article", "Tag"])
    assert_equal ["Article", "Tag"], config.model_names
  end

  test "parses dashboard_configs" do
    dashboards = [{"name" => "pending", "model" => "Article", "scope" => {"status" => "pending"}}]
    config = Backstage::Configuration.new("dashboards" => dashboards)
    assert_equal dashboards, config.dashboard_configs
  end

  test "load_configuration! parses a YAML file" do
    yaml = <<~YAML
      admin_user_method: is_admin?
      redirect_on_failure: /dashboard
      per_page: 10
      models: []
    YAML

    with_config_file(yaml) do |root|
      config = Backstage.load_configuration!(root)
      assert_instance_of Backstage::Configuration, config
      assert_equal :is_admin?, config.admin_user_method
      assert_equal "/dashboard", config.redirect_on_failure
      assert_equal 10, config.per_page
    end
  end

  test "load_configuration! returns defaults when no file exists" do
    Dir.mktmpdir do |dir|
      config = Backstage.load_configuration!(dir)
      assert_equal [], config.model_names
    end
  end

  test "load_configuration! raises ConfigurationError when models is not an array" do
    with_config_file("models: not_a_list") do |root|
      assert_raises(Backstage::ConfigurationError) do
        Backstage.load_configuration!(root)
      end
    end
  end

  test "load_configuration! raises ConfigurationError when per_page is not an integer" do
    with_config_file("per_page: lots") do |root|
      assert_raises(Backstage::ConfigurationError) do
        Backstage.load_configuration!(root)
      end
    end
  end

  test "Backstage.configuration is populated at engine boot" do
    assert_instance_of Backstage::Configuration, Backstage.configuration
  end

  private

  def with_config_file(yaml)
    Dir.mktmpdir do |dir|
      FileUtils.mkdir_p(File.join(dir, "config"))
      File.write(File.join(dir, "config", "backstage.yml"), yaml)
      yield dir
    end
  end
end
