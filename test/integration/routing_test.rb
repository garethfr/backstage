require "test_helper"

class RoutingTest < ActionDispatch::IntegrationTest
  setup do
    set_current_user(mock_user(is_admin: true))
    Article.delete_all
    @article = Article.create!(title: "Test")
    @orig_registry = Backstage.registry
    Backstage.registry.register_dashboard(
      Backstage::DashboardConfig.new("name" => "pending", "model" => "Article", "scope" => {})
    )
  end

  teardown do
    set_current_user(nil)
    Backstage.registry = @orig_registry
  end

  test "GET /admin routes to home#index" do
    get "/admin"
    assert_response :success
  end

  test "GET /admin/articles routes to resources#index" do
    get "/admin/articles"
    assert_response :success
  end

  test "GET /admin/articles/new routes to resources#new" do
    get "/admin/articles/new"
    assert_response :success
  end

  test "GET /admin/articles/:id/edit routes to resources#edit" do
    get "/admin/articles/#{@article.id}/edit"
    assert_response :success
  end

  test "GET /admin/dashboards/pending routes to dashboards#show" do
    get "/admin/dashboards/pending"
    assert_response :success
  end

  test "returns 404 for unregistered resource" do
    get "/admin/ghosts"
    assert_response :not_found
  end

  test "route recognition: index" do
    assert_recognizes(
      {controller: "backstage/resources", action: "index", resource: "articles"},
      {path: "/admin/articles", method: :get}
    )
  end

  test "route recognition: new" do
    assert_recognizes(
      {controller: "backstage/resources", action: "new", resource: "articles"},
      {path: "/admin/articles/new", method: :get}
    )
  end

  test "route recognition: edit" do
    assert_recognizes(
      {controller: "backstage/resources", action: "edit", resource: "articles", id: "1"},
      {path: "/admin/articles/1/edit", method: :get}
    )
  end

  test "route recognition: create" do
    assert_recognizes(
      {controller: "backstage/resources", action: "create", resource: "articles"},
      {path: "/admin/articles", method: :post}
    )
  end

  test "route recognition: update" do
    assert_recognizes(
      {controller: "backstage/resources", action: "update", resource: "articles", id: "1"},
      {path: "/admin/articles/1", method: :patch}
    )
  end

  test "route recognition: destroy" do
    assert_recognizes(
      {controller: "backstage/resources", action: "destroy", resource: "articles", id: "1"},
      {path: "/admin/articles/1", method: :delete}
    )
  end

  test "route recognition: custom action" do
    assert_recognizes(
      {controller: "backstage/actions", action: "create", resource: "articles", id: "1", action_name: "publish"},
      {path: "/admin/articles/1/publish", method: :post}
    )
  end
end
