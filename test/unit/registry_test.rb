require "test_helper"
require "tmpdir"
require "fileutils"

class RegistryTest < ActiveSupport::TestCase
  setup do
    @registry = Backstage::Registry.new
    @orig_configuration = Backstage.configuration
    @orig_registry = Backstage.registry
  end

  teardown do
    Backstage.configuration = @orig_configuration
    Backstage.registry = @orig_registry
  end

  test "starts with no resources" do
    assert_equal [], @registry.all_resources
  end

  test "register stores a resource config" do
    config = Backstage::ResourceConfig.new(String)
    @registry.register("String", config)
    assert_equal config, @registry.resource_for("String")
  end

  test "all_resources returns every registered config" do
    config1 = Backstage::ResourceConfig.new(String)
    config2 = Backstage::ResourceConfig.new(Integer)
    @registry.register("String", config1)
    @registry.register("Integer", config2)
    assert_equal [config1, config2], @registry.all_resources
  end

  test "resource_for raises KeyError for unknown model name" do
    assert_raises(KeyError) { @registry.resource_for("Nonexistent") }
  end

  test "Backstage.registry is populated after boot" do
    assert_instance_of Backstage::Registry, Backstage.registry
  end

  test "load_configuration! raises ConfigurationError for unknown model class" do
    with_config_file("models:\n  - GhostModel99\n") do |root|
      assert_raises(Backstage::ConfigurationError) do
        Backstage.load_configuration!(root)
      end
    end
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
