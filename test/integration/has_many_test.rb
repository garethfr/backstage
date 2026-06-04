require "test_helper"

ActiveRecord::Schema.define do
  create_table :backstage_hm_tags, force: true do |t|
    t.string :name
    t.timestamps
  end
  create_table :backstage_hm_articles, force: true do |t|
    t.string :title
    t.timestamps
  end
  create_table :backstage_hm_articles_backstage_hm_tags, force: true, id: false do |t|
    t.integer :backstage_hm_article_id
    t.integer :backstage_hm_tag_id
  end
end

class BackstageHmTag < ApplicationRecord
  self.table_name = "backstage_hm_tags"
  has_and_belongs_to_many :backstage_hm_articles,
    join_table: "backstage_hm_articles_backstage_hm_tags"
  validates :name, presence: true
end

class BackstageHmArticle < ApplicationRecord
  self.table_name = "backstage_hm_articles"
  has_and_belongs_to_many :backstage_hm_tags,
    join_table: "backstage_hm_articles_backstage_hm_tags"
  validates :title, presence: true
end

class HasManyTest < ActionDispatch::IntegrationTest
  setup do
    set_current_user(mock_user(is_admin: true))
    BackstageHmTag.delete_all
    BackstageHmArticle.delete_all

    @tag1 = BackstageHmTag.create!(name: "Ruby")
    @tag2 = BackstageHmTag.create!(name: "Rails")
    @tag3 = BackstageHmTag.create!(name: "Python")

    @article = BackstageHmArticle.create!(title: "Test Post")
    @article.backstage_hm_tags << @tag1

    tag_config = Backstage::AutoDiscovery.build(BackstageHmTag)
    article_config = Backstage::AutoDiscovery.build(BackstageHmArticle)
    article_config.has_many :backstage_hm_tags, display_column: :name

    @orig_registry = Backstage.registry
    Backstage.registry = Backstage::Registry.new
    Backstage.registry.register("BackstageHmTag", tag_config)
    Backstage.registry.register("BackstageHmArticle", article_config)
  end

  teardown do
    Backstage.registry = @orig_registry
    set_current_user(nil)
  end

  test "edit renders checkboxes for all associated records" do
    get "/admin/backstage_hm_articles/#{@article.id}/edit"
    assert_response :success
    assert_match "Ruby", response.body
    assert_match "Rails", response.body
    assert_match "Python", response.body
    assert_match 'type="checkbox"', response.body
  end

  test "currently associated tags are checked" do
    get "/admin/backstage_hm_articles/#{@article.id}/edit"
    assert_match 'checked="checked"', response.body
  end

  test "update adds association" do
    patch "/admin/backstage_hm_articles/#{@article.id}",
      params: {backstage_hm_article: {backstage_hm_tag_ids: [@tag2.id]}}
    assert_redirected_to "/admin/backstage_hm_articles/#{@article.id}/edit"
    assert_includes @article.reload.backstage_hm_tags.map(&:name), "Rails"
  end
end
