require "test_helper"

ActiveRecord::Schema.define do
  create_table :backstage_dash_articles, force: true do |t|
    t.string :title
    t.integer :status, default: 0
    t.timestamps
  end
end

class BackstageDashArticle < ApplicationRecord
  self.table_name = "backstage_dash_articles"
  enum :status, {draft: 0, published: 1}
  validates :title, presence: true
end

class DashboardsTest < ActionDispatch::IntegrationTest
  setup do
    set_current_user(mock_user(is_admin: true))
    BackstageDashArticle.delete_all

    BackstageDashArticle.create!(title: "Draft 1", status: :draft)
    BackstageDashArticle.create!(title: "Draft 2", status: :draft)
    BackstageDashArticle.create!(title: "Published 1", status: :published)

    rc = Backstage::AutoDiscovery.build(BackstageDashArticle)
    dc = Backstage::DashboardConfig.new(
      "name" => "drafts",
      "model" => "BackstageDashArticle",
      "scope" => {"status" => 0}
    )

    @orig_registry = Backstage.registry
    Backstage.registry = Backstage::Registry.new
    Backstage.registry.register("BackstageDashArticle", rc)
    Backstage.registry.register_dashboard(dc)
  end

  teardown do
    Backstage.registry = @orig_registry
    set_current_user(nil)
  end

  test "dashboard renders successfully" do
    get "/admin/dashboards/drafts"
    assert_response :success
  end

  test "dashboard shows only scoped records" do
    get "/admin/dashboards/drafts"
    assert_match "Draft 1", response.body
    assert_match "Draft 2", response.body
    assert_no_match "Published 1", response.body
  end

  test "dashboard paginates results" do
    per_page = Backstage.configuration.per_page
    (per_page + 2).times { |i| BackstageDashArticle.create!(title: "D #{i}", status: :draft) }
    get "/admin/dashboards/drafts"
    assert_response :success
    get "/admin/dashboards/drafts", params: {page: 2}
    assert_response :success
  end

  test "dashboard pagination shows first and last page links when there are many pages" do
    BackstageDashArticle.delete_all
    per_page = Backstage.configuration.per_page
    (per_page * 15).times { |i| BackstageDashArticle.create!(title: "D #{i}", status: :draft) }
    get "/admin/dashboards/drafts", params: {page: 8}
    assert_match "page=1", response.body
    assert_match "page=15", response.body
  end

  test "dashboard pagination shows only 5 pages around current page" do
    BackstageDashArticle.delete_all
    per_page = Backstage.configuration.per_page
    (per_page * 15).times { |i| BackstageDashArticle.create!(title: "D #{i}", status: :draft) }
    get "/admin/dashboards/drafts", params: {page: 8}
    assert_match "page=6", response.body
    assert_match "page=10", response.body
    assert_no_match "page=5\"", response.body
    assert_no_match "page=11\"", response.body
  end
end
