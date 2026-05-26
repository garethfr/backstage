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

  test "field new column is added to index_fields when fields has not been called" do
    with_dsl("article.rb" => "Backstage.resource(:Article) { |c| c.field :virtual_col, as: :string }") do
      config = Backstage.registry.resource_for("Article")
      assert_includes config.index_fields.map(&:name), :virtual_col
    end
  end

  test "field new column is not added to index_fields when fields has been called explicitly" do
    dsl = "Backstage.resource(:Article) { |c| c.fields :title; c.field :virtual_col, as: :string }"
    with_dsl("article.rb" => dsl) do
      config = Backstage.registry.resource_for("Article")
      assert_equal [:title], config.index_fields.map(&:name)
      assert_includes config.edit_fields.map(&:name), :virtual_col
    end
  end

  # --- row DSL ---

  test "row creates a container field with named sub_fields" do
    with_dsl("article.rb" => "Backstage.resource(:Article) { |c| c.row :title, :body }") do
      config = Backstage.registry.resource_for("Article")
      row = config.edit_fields.find(&:row?)
      assert_not_nil row
      assert_equal [:title, :body], row.sub_fields.map(&:name)
    end
  end

  test "row removes constituent fields from top-level edit_fields" do
    with_dsl("article.rb" => "Backstage.resource(:Article) { |c| c.row :title, :body }") do
      config = Backstage.registry.resource_for("Article")
      top_names = config.edit_fields.reject(&:row?).map(&:name)
      assert_not_includes top_names, :title
      assert_not_includes top_names, :body
    end
  end

  # --- section DSL ---

  test "section wraps block contents into a collapsible container" do
    dsl = "Backstage.resource(:Article) { |c| c.section('Details') { c.row :title, :body } }"
    with_dsl("article.rb" => dsl) do
      config = Backstage.registry.resource_for("Article")
      section = config.edit_fields.find(&:section?)
      assert_not_nil section
      assert_equal "Details", section.heading
      assert section.sub_fields.any?(&:row?)
    end
  end

  test "section with collapsed: true marks the section as collapsed" do
    dsl = "Backstage.resource(:Article) { |c| c.section('Details', collapsed: true) { c.field :title } }"
    with_dsl("article.rb" => dsl) do
      config = Backstage.registry.resource_for("Article")
      assert config.edit_fields.find(&:section?).collapsed?
    end
  end

  test "section without collapsed option defaults to not collapsed" do
    dsl = "Backstage.resource(:Article) { |c| c.section('Details') { c.field :title } }"
    with_dsl("article.rb" => dsl) do
      config = Backstage.registry.resource_for("Article")
      assert_not config.edit_fields.find(&:section?).collapsed?
    end
  end

  test "section resets current_target even when block raises" do
    config = Backstage::AutoDiscovery.build(Article)
    assert_raises(RuntimeError) do
      config.section("Boom") { raise "oops" }
    end
    # A subsequent field call must go to top-level edit_fields, not a stale target
    config.field(:title, readonly: true)
    top_level = config.edit_fields.reject(&:section?)
    assert_includes top_level.map(&:name), :title
  end

  test "find_field searches inside container sub_fields" do
    config = Backstage::AutoDiscovery.build(Article)
    config.section("Details") { config.field(:title, readonly: true) }
    # Calling section again with the same field must find the existing one in sub_fields
    # and not add a duplicate top-level field
    title_fields = (config.edit_fields + config.edit_fields.flat_map(&:sub_fields))
      .select { |f| f.name == :title }
    assert_equal 1, title_fields.count
  end

  test "field for existing field inside section moves it to section sub_fields" do
    dsl = "Backstage.resource(:Article) { |c| c.section('Details') { c.field :title, readonly: true } }"
    with_dsl("article.rb" => dsl) do
      config = Backstage.registry.resource_for("Article")
      section = config.edit_fields.find(&:section?)
      assert_includes section.sub_fields.map(&:name), :title
      assert_not_includes config.edit_fields.reject(&:section?).map(&:name), :title
      assert section.sub_fields.find { |f| f.name == :title }.readonly?
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
