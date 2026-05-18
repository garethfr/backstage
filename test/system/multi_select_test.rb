require_relative "application_system_test_case"

ActiveRecord::Schema.define do
  create_table :ms_tags, force: true do |t|
    t.string :name
    t.timestamps
  end
  create_table :ms_articles, force: true do |t|
    t.string :title
    t.timestamps
  end
  create_table :ms_articles_ms_tags, force: true, id: false do |t|
    t.integer :ms_article_id
    t.integer :ms_tag_id
  end
end

class MsTag < ApplicationRecord
  self.table_name = "ms_tags"
  has_and_belongs_to_many :ms_articles,
    join_table: "ms_articles_ms_tags"
  validates :name, presence: true
end

class MsArticle < ApplicationRecord
  self.table_name = "ms_articles"
  has_and_belongs_to_many :ms_tags,
    join_table: "ms_articles_ms_tags"
  validates :title, presence: true
end

class MultiSelectTest < ApplicationSystemTestCase
  setup do
    MsTag.delete_all
    MsArticle.delete_all

    @ruby = MsTag.create!(name: "Ruby")
    @rails = MsTag.create!(name: "Rails")
    @python = MsTag.create!(name: "Python")
    @java = MsTag.create!(name: "Java")

    @article = MsArticle.create!(title: "Test Post")
    @article.ms_tags << @ruby

    tag_config = Backstage::AutoDiscovery.build(MsTag)
    article_config = Backstage::AutoDiscovery.build(MsArticle)
    article_config.has_many :ms_tags, display_column: :name

    @orig_registry = Backstage.registry
    Backstage.registry = Backstage::Registry.new
    Backstage.registry.register("MsTag", tag_config)
    Backstage.registry.register("MsArticle", article_config)
  end

  teardown { Backstage.registry = @orig_registry }

  test "search input filters checkboxes by label text" do
    visit "/admin/ms_articles/#{@article.id}/edit"

    assert_selector "input[type=checkbox]", count: 4

    fill_in "Search ms tags…", with: "ra"

    assert_selector "input[type=checkbox]", visible: true, count: 1
    assert_selector "label", text: "Rails", visible: true
    assert_no_selector "label", text: "Ruby", visible: true
    assert_no_selector "label", text: "Python", visible: true
  end

  test "clearing search restores all checkboxes" do
    visit "/admin/ms_articles/#{@article.id}/edit"
    fill_in "Search ms tags…", with: "ra"
    fill_in "Search ms tags…", with: ""
    assert_selector "input[type=checkbox]", visible: true, count: 4
  end
end
