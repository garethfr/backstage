require "test_helper"

class HomeTest < ActionDispatch::IntegrationTest
  setup { set_current_user(mock_user(is_admin: true)) }
  teardown { set_current_user(nil) }

  test "GET /admin returns 200" do
    get "/admin"
    assert_response :success
  end
end
