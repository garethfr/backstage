require "test_helper"

class HomeDashboardsTest < ActionDispatch::IntegrationTest
  setup do
    set_current_user(mock_user(is_admin: true))
    Article.delete_all
    Article.create!(title: "Alpha")
    Article.create!(title: "Beta")

    @orig_registry = Backstage.registry
    Backstage.registry.register_dashboard(
      Backstage::DashboardConfig.new("name" => "all_articles", "model" => "Article", "scope" => {})
    )
  end

  teardown do
    set_current_user(nil)
    Backstage.registry = @orig_registry
  end

  test "home page lists dashboards" do
    get "/admin"
    assert_response :success
    assert_match "all_articles".humanize, response.body
  end

  test "home page shows dashboard record count" do
    get "/admin"
    assert_match "2", response.body
  end

  test "home page links to dashboard" do
    get "/admin"
    assert_match "/admin/dashboards/all_articles", response.body
  end
end
