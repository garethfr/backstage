require "test_helper"

ActiveRecord::Schema.define do
  create_table :backstage_nested_articles, force: true do |t|
    t.string :title
    t.timestamps
  end
  create_table :backstage_nested_extras, force: true do |t|
    t.integer :backstage_nested_article_id, null: false
    t.string :key, null: false
    t.string :value
    t.timestamps
  end
end

class BackstageNestedExtra < ApplicationRecord
  self.table_name = "backstage_nested_extras"
  belongs_to :backstage_nested_article
end

class BackstageNestedArticle < ApplicationRecord
  self.table_name = "backstage_nested_articles"
  has_many :backstage_nested_extras, dependent: :destroy
  accepts_nested_attributes_for :backstage_nested_extras,
    allow_destroy: true,
    reject_if: :all_blank
end

class NestedTest < ActionDispatch::IntegrationTest
  setup do
    set_current_user(mock_user(is_admin: true))
    BackstageNestedExtra.delete_all
    BackstageNestedArticle.delete_all

    @article = BackstageNestedArticle.create!(title: "Test Article")
    @extra1 = BackstageNestedExtra.create!(backstage_nested_article: @article, key: "source", value: "web")
    @extra2 = BackstageNestedExtra.create!(backstage_nested_article: @article, key: "lang", value: "fr")

    config = Backstage::AutoDiscovery.build(BackstageNestedArticle)
    config.nested :backstage_nested_extras,
      fields: [:key, :value],
      readonly_fields: [:key]

    @orig_registry = Backstage.registry
    Backstage.registry = Backstage::Registry.new
    Backstage.registry.register("BackstageNestedArticle", config)
  end

  teardown do
    Backstage.registry = @orig_registry
    set_current_user(nil)
  end

  test "edit renders nested records" do
    get "/admin/backstage_nested_articles/#{@article.id}/edit"
    assert_response :success
    assert_match "source", response.body
    assert_match "web", response.body
    assert_match "lang", response.body
    assert_match "fr", response.body
  end

  test "readonly fields are rendered as text, not inputs" do
    get "/admin/backstage_nested_articles/#{@article.id}/edit"
    assert_match "source", response.body
    assert_no_match 'name="backstage_nested_article[backstage_nested_extras_attributes][0][key]"', response.body
  end

  test "writable fields are rendered as inputs" do
    get "/admin/backstage_nested_articles/#{@article.id}/edit"
    assert_match 'name="backstage_nested_article[backstage_nested_extras_attributes][0][value]"', response.body
  end

  test "update saves writable nested field values" do
    patch "/admin/backstage_nested_articles/#{@article.id}",
      params: {
        backstage_nested_article: {
          backstage_nested_extras_attributes: {
            "0" => {id: @extra1.id, value: "mobile"}
          }
        }
      }
    assert_redirected_to "/admin/backstage_nested_articles"
    assert_equal "mobile", @extra1.reload.value
  end

  test "readonly fields are not saved even if submitted" do
    patch "/admin/backstage_nested_articles/#{@article.id}",
      params: {
        backstage_nested_article: {
          backstage_nested_extras_attributes: {
            "0" => {id: @extra1.id, key: "hacked", value: "mobile"}
          }
        }
      }
    assert_equal "source", @extra1.reload.key
  end

  # --- delete ---

  test "edit page renders a destroy button for each nested row" do
    get "/admin/backstage_nested_articles/#{@article.id}/edit"
    assert_match "data-nested-destroy", response.body
  end

  test "edit page renders a hidden _destroy field for each nested row" do
    get "/admin/backstage_nested_articles/#{@article.id}/edit"
    assert_match "_destroy", response.body
  end

  test "_destroy is permitted and destroys the nested record when set to 1" do
    patch "/admin/backstage_nested_articles/#{@article.id}",
      params: {
        backstage_nested_article: {
          backstage_nested_extras_attributes: {
            "0" => {id: @extra1.id, _destroy: "1"}
          }
        }
      }
    assert_redirected_to "/admin/backstage_nested_articles"
    assert_not BackstageNestedExtra.exists?(@extra1.id)
  end

  # --- add new ---

  test "edit page renders an empty add row" do
    get "/admin/backstage_nested_articles/#{@article.id}/edit"
    # Should have at least one input with no value for adding a new record
    assert_match "data-nested-new-row", response.body
  end

  test "submitting the empty add row with values creates a new nested record" do
    # Use a config with no readonly_fields so both key and value are writable
    config = Backstage::AutoDiscovery.build(BackstageNestedArticle)
    config.nested :backstage_nested_extras, fields: [:key, :value]
    Backstage.registry = Backstage::Registry.new
    Backstage.registry.register("BackstageNestedArticle", config)

    assert_difference "BackstageNestedExtra.count", 1 do
      patch "/admin/backstage_nested_articles/#{@article.id}",
        params: {
          backstage_nested_article: {
            backstage_nested_extras_attributes: {
              "2" => {key: "color", value: "red"}
            }
          }
        }
    end
  end
end
