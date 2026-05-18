require "test_helper"

class LayoutTest < ActionDispatch::IntegrationTest
  setup do
    set_current_user(mock_user(is_admin: true))
    Article.delete_all
  end

  teardown { set_current_user(nil) }

  test "layout includes nav with model links" do
    get "/admin"
    assert_response :success
    assert_match "<nav", response.body
    assert_match "/admin/articles", response.body
  end

  test "layout includes link to home" do
    get "/admin"
    assert_response :success
    assert_match %r{href="/admin/?"}, response.body
  end

  test "layout references backstage stylesheet" do
    get "/admin"
    assert_match "backstage", response.body
    assert_match "stylesheet", response.body
  end
end
