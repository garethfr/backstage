require "test_helper"
require "tmpdir"
require "fileutils"

class DslLoaderTest < ActiveSupport::TestCase
  setup do
    @orig_configuration = Backstage.configuration
    @orig_registry = Backstage.registry
  end

  teardown do
    Backstage.configuration = @orig_configuration
    Backstage.registry = @orig_registry
  end

  test "DSL file is loaded after auto-discovery" do
    with_dsl_root("article.rb" => "Backstage.resource(:Article) {}") do |root|
      Backstage.load_configuration!(root)
      assert_not_nil Backstage.registry.resource_for("Article")
    end
  end

  test "DSL block receives the ResourceConfig and can mutate it" do
    dsl = "Backstage.resource(:Article) { |c| c.display_column(:title) }"
    with_dsl_root("article.rb" => dsl) do |root|
      Backstage.load_configuration!(root)
      config = Backstage.registry.resource_for("Article")
      assert_equal :title, config.display_column
    end
  end

  test "DSL is loaded for every model file in config/backstage/" do
    files = {
      "article.rb" => "Backstage.resource(:Article) {}",
      "ignored.rb" => ""
    }
    with_dsl_root(files) do |root|
      assert_nothing_raised { Backstage.load_configuration!(root) }
    end
  end

  test "Backstage.resource raises for unregistered model" do
    dsl = "Backstage.resource(:Ghost) {}"
    with_dsl_root("ghost.rb" => dsl) do |root|
      assert_raises(Backstage::ConfigurationError) do
        Backstage.load_configuration!(root)
      end
    end
  end

  private

  def with_dsl_root(files)
    Dir.mktmpdir do |dir|
      FileUtils.mkdir_p(File.join(dir, "config", "backstage"))
      yaml = "models:\n  - Article\n"
      File.write(File.join(dir, "config", "backstage.yml"), yaml)
      files.each do |name, content|
        File.write(File.join(dir, "config", "backstage", name), content)
      end
      yield dir
    end
  end
end
