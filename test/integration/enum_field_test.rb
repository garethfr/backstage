require "test_helper"

class EnumFieldTest < ActionDispatch::IntegrationTest
  setup do
    set_current_user(mock_user(is_admin: true))

    ActiveRecord::Schema.define do
      create_table :backstage_enum_items, force: true do |t|
        t.string :title
        t.integer :status
        t.timestamps
      end
    end

    unless defined?(BackstageEnumItem)
      Object.const_set(:BackstageEnumItem, Class.new(ApplicationRecord) {
        self.table_name = "backstage_enum_items"
        enum :status, {draft: 0, published: 1, archived: 2}
        validates :title, presence: true
      })
    end

    config = Backstage::AutoDiscovery.build(BackstageEnumItem)
    @orig_registry = Backstage.registry
    Backstage.registry = Backstage::Registry.new
    Backstage.registry.register("BackstageEnumItem", config)

    @item = BackstageEnumItem.create!(title: "Item 1", status: :draft)
    BackstageEnumItem.create!(title: "Item 2", status: :published)
  end

  teardown do
    Backstage.registry = @orig_registry
    set_current_user(nil)
  end

  test "edit form renders a select for enum field" do
    get "/admin/backstage_enum_items/#{@item.id}/edit"
    assert_response :success
    assert_match "<select", response.body
    assert_match "draft", response.body
    assert_match "published", response.body
    assert_match "archived", response.body
  end

  test "index shows enum filter links" do
    get "/admin/backstage_enum_items"
    assert_response :success
    assert_match "draft", response.body
    assert_match "published", response.body
    assert_match "archived", response.body
  end

  test "enum filter by status" do
    get "/admin/backstage_enum_items", params: {status: "published"}
    assert_response :success
    assert_match "Item 2", response.body
    assert_no_match "Item 1", response.body
  end

  test "index displays human-readable enum value" do
    get "/admin/backstage_enum_items"
    assert_response :success
    assert_match "Draft", response.body
    assert_match "Published", response.body
  end
end
