require "test_helper"

class AutoDiscoveryTest < ActiveSupport::TestCase
  # Create a persistent test table and model for this test file.
  ActiveRecord::Schema.define do
    create_table :backstage_test_items, force: true do |t|
      t.string :name
      t.string :email
      t.integer :count
      t.text :body
      t.boolean :active
      t.date :published_on
      t.datetime :processed_at
      t.integer :status
      t.timestamps
    end
  end

  class TestItem < ActiveRecord::Base
    self.table_name = "backstage_test_items"
    enum :status, {draft: 0, published: 1}
  end

  setup do
    @config = Backstage::AutoDiscovery.build(TestItem)
  end

  test "returns a ResourceConfig" do
    assert_instance_of Backstage::ResourceConfig, @config
  end

  test "sets model_class" do
    assert_equal TestItem, @config.model_class
  end

  test "discovers string columns as :string" do
    field = field_named(:email)
    assert_not_nil field
    assert_equal :string, field.type
  end

  test "discovers integer columns as :integer" do
    field = field_named(:count)
    assert_not_nil field
    assert_equal :integer, field.type
  end

  test "discovers text columns as :text" do
    field = field_named(:body)
    assert_not_nil field
    assert_equal :text, field.type
  end

  test "discovers boolean columns as :boolean" do
    field = field_named(:active)
    assert_not_nil field
    assert_equal :boolean, field.type
  end

  test "discovers date columns as :date" do
    field = field_named(:published_on)
    assert_not_nil field
    assert_equal :date, field.type
  end

  test "discovers datetime columns as :datetime" do
    field = field_named(:processed_at)
    assert_not_nil field
    assert_equal :datetime, field.type
  end

  test "excludes system columns (id, created_at, updated_at) from index_fields" do
    names = @config.index_fields.map(&:name)
    assert_not_includes names, :id
    assert_not_includes names, :created_at
    assert_not_includes names, :updated_at
  end

  test "excludes system columns from edit_fields" do
    names = @config.edit_fields.map(&:name)
    assert_not_includes names, :id
    assert_not_includes names, :created_at
    assert_not_includes names, :updated_at
  end

  test "sets display_column to :name when present" do
    assert_equal :name, @config.display_column
  end

  test "falls back through :title then :email then :id for display_column" do
    ActiveRecord::Schema.define do
      create_table :backstage_fallback_items, force: true do |t|
        t.string :email
        t.timestamps
      end
    end
    model = Class.new(ActiveRecord::Base) { self.table_name = "backstage_fallback_items" }
    config = Backstage::AutoDiscovery.build(model)
    assert_equal :email, config.display_column
  end

  test "detects enum fields via defined_enums" do
    field = field_named(:status)
    assert_not_nil field
    assert_equal :enum, field.type
  end

  test "enum field has correct enum_values" do
    field = field_named(:status)
    assert_includes field.enum_values, ["Draft", "draft"]
    assert_includes field.enum_values, ["Published", "published"]
  end

  test "excludes enum backing column from non-enum fields" do
    non_enum_field = @config.index_fields.find { |f| f.name == :status && f.type != :enum }
    assert_nil non_enum_field
  end

  private

  def field_named(name)
    @config.index_fields.find { |f| f.name == name }
  end
end
