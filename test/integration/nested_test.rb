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

  test "readonly fields are rendered as plain text, not inputs, for existing rows" do
    get "/admin/backstage_nested_articles/#{@article.id}/edit"
    assert_no_match 'name="backstage_nested_article[backstage_nested_extras_attributes][0][key]"',
      response.body
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

  # --- add new (Bug 1: template approach, not static DOM row) ---

  test "edit page renders an Add button and a template element, not a static new row" do
    get "/admin/backstage_nested_articles/#{@article.id}/edit"
    assert_match "data-nested-add", response.body
    assert_match "data-nested-template", response.body
    assert_no_match "data-nested-new-row", response.body
  end

  test "submitting a new record via numeric index creates the nested record" do
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

  # --- Bug 2: readonly fields must appear as inputs in the new-row template ---

  test "new-row template includes readonly fields as inputs so new records can be fully populated" do
    get "/admin/backstage_nested_articles/#{@article.id}/edit"
    # Find the template section — key is readonly but must still be present as an input in the template
    template_html = response.body[/data-nested-template.*?<\/template>/m]
    assert_not_nil template_html, "expected a data-nested-template element"
    assert_match "[key]", template_html
  end

  # --- Bug 3: readonly nested fields must be permitted so new records save correctly ---

  test "submitting a new nested record with a readonly field saves the readonly field value" do
    # Config has key as readonly (display-only on existing rows), but new records need to set it
    assert_difference "BackstageNestedExtra.count", 1 do
      patch "/admin/backstage_nested_articles/#{@article.id}",
        params: {
          backstage_nested_article: {
            backstage_nested_extras_attributes: {
              "2" => {key: "newkey", value: "newval"}
            }
          }
        }
    end
    assert_equal "newkey", BackstageNestedExtra.order(:id).last.key
  end
end
