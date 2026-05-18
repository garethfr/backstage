require "test_helper"

class FieldPartialsTest < ActionDispatch::IntegrationTest
  setup do
    set_current_user(mock_user(is_admin: true))
    ActiveRecord::Schema.define do
      create_table :backstage_fp_items, force: true do |t|
        t.string :name
        t.integer :count
        t.text :body
        t.boolean :active
        t.date :published_on
        t.datetime :processed_at
        t.timestamps
      end
    end
    unless defined?(BackstageFpItem)
      Object.const_set(:BackstageFpItem, Class.new(ApplicationRecord) {
        self.table_name = "backstage_fp_items"
        validates :name, presence: true
      })
    end

    config = Backstage::AutoDiscovery.build(BackstageFpItem)
    @orig_registry = Backstage.registry
    Backstage.registry = Backstage::Registry.new
    Backstage.registry.register("BackstageFpItem", config)

    @item = BackstageFpItem.create!(
      name: "TestItem", count: 42, body: "Some text",
      active: true, published_on: Date.today, processed_at: Time.now
    )
  end

  teardown do
    Backstage.registry = @orig_registry
    set_current_user(nil)
  end

  test "edit renders string field" do
    get "/admin/backstage_fp_items/#{@item.id}/edit"
    assert_response :success
    assert_match 'type="text"', response.body
    assert_match "TestItem", response.body
  end

  test "edit renders integer field" do
    get "/admin/backstage_fp_items/#{@item.id}/edit"
    assert_response :success
    assert_match 'type="number"', response.body
    assert_match "42", response.body
  end

  test "edit renders text field" do
    get "/admin/backstage_fp_items/#{@item.id}/edit"
    assert_response :success
    assert_match "<textarea", response.body
    assert_match "Some text", response.body
  end

  test "edit renders boolean field" do
    get "/admin/backstage_fp_items/#{@item.id}/edit"
    assert_response :success
    assert_match 'type="checkbox"', response.body
  end

  test "edit renders date field" do
    get "/admin/backstage_fp_items/#{@item.id}/edit"
    assert_response :success
    assert_match 'type="date"', response.body
  end

  test "edit renders datetime field" do
    get "/admin/backstage_fp_items/#{@item.id}/edit"
    assert_response :success
    assert_match 'type="datetime-local"', response.body
  end
end
