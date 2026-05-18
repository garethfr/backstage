require "test_helper"

class ResourceConfigDslTest < ActiveSupport::TestCase
  setup do
    @orig_configuration = Backstage.configuration
    @orig_registry = Backstage.registry
  end

  teardown do
    Backstage.configuration = @orig_configuration
    Backstage.registry = @orig_registry
  end

  # --- fields DSL (BACK-019) ---

  test "fields sets index_fields to the declared columns in order" do
    with_dsl("article.rb" => "Backstage.resource(:Article) { |c| c.fields :title }") do
      config = Backstage.registry.resource_for("Article")
      assert_equal [:title], config.index_fields.map(&:name)
    end
  end

  test "fields accepts multiple column names" do
    with_dsl("article.rb" => "Backstage.resource(:Article) { |c| c.fields :title, :id }") do
      config = Backstage.registry.resource_for("Article")
      assert_equal [:title, :id], config.index_fields.map(&:name)
    end
  end

  test "exclude removes column from index_fields" do
    with_dsl("article.rb" => "Backstage.resource(:Article) { |c| c.exclude :title }") do
      config = Backstage.registry.resource_for("Article")
      assert_not_includes config.index_fields.map(&:name), :title
    end
  end

  test "exclude removes column from edit_fields" do
    with_dsl("article.rb" => "Backstage.resource(:Article) { |c| c.exclude :title }") do
      config = Backstage.registry.resource_for("Article")
      assert_not_includes config.edit_fields.map(&:name), :title
    end
  end

  test "display_column DSL overrides auto-discovered value" do
    with_dsl("article.rb" => "Backstage.resource(:Article) { |c| c.display_column :id }") do
      config = Backstage.registry.resource_for("Article")
      assert_equal :id, config.display_column
    end
  end

  # --- field override DSL (BACK-020) ---

  test "field override sets readonly option" do
    with_dsl("article.rb" => "Backstage.resource(:Article) { |c| c.field :title, readonly: true }") do
      config = Backstage.registry.resource_for("Article")
      f = config.edit_fields.find { |x| x.name == :title }
      assert f.readonly?
    end
  end

  test "field override sets custom partial" do
    with_dsl("article.rb" => "Backstage.resource(:Article) { |c| c.field :title, partial: 'my/custom' }") do
      config = Backstage.registry.resource_for("Article")
      f = config.edit_fields.find { |x| x.name == :title }
      assert_equal "my/custom", f.partial_path
    end
  end

  test "field override does not affect other fields" do
    dsl = "Backstage.resource(:Article) { |c| c.field :title, readonly: true; c.field :extra, as: :string }"
    with_dsl("article.rb" => dsl) do
      config = Backstage.registry.resource_for("Article")
      assert config.edit_fields.find { |x| x.name == :title }.readonly?
      assert_not config.edit_fields.find { |x| x.name == :extra }.readonly?
    end
  end

  test "field can create a new field not in auto-discovered list" do
    with_dsl("article.rb" => "Backstage.resource(:Article) { |c| c.field :custom_virtual, as: :string }") do
      config = Backstage.registry.resource_for("Article")
      f = config.edit_fields.find { |x| x.name == :custom_virtual }
      assert_not_nil f
      assert_equal :string, f.type
    end
  end

  private

  def with_dsl(files)
    Dir.mktmpdir do |dir|
      FileUtils.mkdir_p(File.join(dir, "config", "backstage"))
      File.write(File.join(dir, "config", "backstage.yml"), "models:\n  - Article\n")
      files.each do |name, content|
        File.write(File.join(dir, "config", "backstage", name), content)
      end
      Backstage.load_configuration!(dir)
      yield
    end
  end
end
