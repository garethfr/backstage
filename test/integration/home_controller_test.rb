require "test_helper"

class HomeControllerTest < ActionDispatch::IntegrationTest
  setup do
    set_current_user(mock_user(is_admin: true))
    Article.delete_all
  end

  teardown { set_current_user(nil) }

  test "index renders successfully" do
    get "/admin"
    assert_response :success
  end

  test "index lists registered models" do
    get "/admin"
    assert_match "Article", response.body
  end

  test "index shows record count" do
    3.times { |i| Article.create!(title: "Article #{i}") }
    get "/admin"
    assert_match "3", response.body
  end

  test "index links to resource index" do
    get "/admin"
    assert_match "/admin/articles", response.body
  end
end
