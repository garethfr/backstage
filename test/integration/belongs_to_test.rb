require "test_helper"

class BelongsToTest < ActionDispatch::IntegrationTest
  setup do
    set_current_user(mock_user(is_admin: true))

    ActiveRecord::Schema.define do
      create_table :backstage_bt_authors, force: true do |t|
        t.string :name
        t.timestamps
      end
      create_table :backstage_bt_posts, force: true do |t|
        t.string :title
        t.integer :backstage_bt_author_id
        t.timestamps
      end
    end

    unless defined?(BackstageBtAuthor)
      Object.const_set(:BackstageBtAuthor, Class.new(ApplicationRecord) {
        self.table_name = "backstage_bt_authors"
        has_many :backstage_bt_posts
        validates :name, presence: true
      })
      Object.const_set(:BackstageBtPost, Class.new(ApplicationRecord) {
        self.table_name = "backstage_bt_posts"
        belongs_to :backstage_bt_author
        validates :title, presence: true
      })
    end

    @author1 = BackstageBtAuthor.create!(name: "Alice")
    @author2 = BackstageBtAuthor.create!(name: "Bob")
    @post = BackstageBtPost.create!(title: "Post 1", backstage_bt_author: @author1)

    author_config = Backstage::AutoDiscovery.build(BackstageBtAuthor)
    post_config = Backstage::AutoDiscovery.build(BackstageBtPost)
    post_config.belongs_to :backstage_bt_author, display_column: :name

    @orig_registry = Backstage.registry
    Backstage.registry = Backstage::Registry.new
    Backstage.registry.register("BackstageBtAuthor", author_config)
    Backstage.registry.register("BackstageBtPost", post_config)
  end

  teardown do
    Backstage.registry = @orig_registry
    set_current_user(nil)
  end

  test "index shows display column value instead of raw foreign key id" do
    get "/admin/backstage_bt_posts"
    assert_response :success
    assert_match "Alice", response.body
    assert_no_match ">#{@author1.id}<", response.body
  end

  test "index links belongs_to value to the related record edit page" do
    get "/admin/backstage_bt_posts"
    assert_match "backstage_bt_authors/#{@author1.id}/edit", response.body
  end

  test "edit renders a select for belongs_to association" do
    get "/admin/backstage_bt_posts/#{@post.id}/edit"
    assert_response :success
    assert_match "<select", response.body
    assert_match "Alice", response.body
    assert_match "Bob", response.body
  end

  test "select includes blank option" do
    get "/admin/backstage_bt_posts/#{@post.id}/edit"
    assert_match '<option value=""', response.body
  end

  test "update saves the foreign key" do
    patch "/admin/backstage_bt_posts/#{@post.id}",
      params: {backstage_bt_post: {backstage_bt_author_id: @author2.id}}
    assert_redirected_to "/admin/backstage_bt_posts"
    assert_equal @author2.id, @post.reload.backstage_bt_author_id
  end

  test "belongs_to does not append to index_fields when fields has been called explicitly" do
    post_config = Backstage::AutoDiscovery.build(BackstageBtPost)
    post_config.fields(:title)
    post_config.belongs_to :backstage_bt_author, display_column: :name
    assert_equal [:title], post_config.index_fields.map(&:name)
    assert_includes post_config.edit_fields.map(&:name), :backstage_bt_author_id
  end
end
