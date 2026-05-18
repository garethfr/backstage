require "test_helper"

class AuthTest < ActionDispatch::IntegrationTest
  teardown { set_current_user(nil) }

  test "redirects to redirect_on_failure when current_user is nil" do
    get "/admin"
    assert_redirected_to "/"
  end

  test "redirects when current_user fails the admin check" do
    set_current_user(mock_user(is_admin: false))
    get "/admin"
    assert_redirected_to "/"
  end

  test "allows access when current_user passes the admin check" do
    set_current_user(mock_user(is_admin: true))
    get "/admin"
    assert_response :success
  end
end
