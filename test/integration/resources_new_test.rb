require "test_helper"

class ResourcesNewTest < ActionDispatch::IntegrationTest
  setup do
    set_current_user(mock_user(is_admin: true))
    Article.delete_all
  end

  teardown { set_current_user(nil) }

  test "new renders successfully" do
    get "/admin/articles/new"
    assert_response :success
  end

  test "create with valid params redirects to edit" do
    post "/admin/articles", params: {article: {title: "New Article"}}
    article = Article.last
    assert_not_nil article
    assert_equal "New Article", article.title
    assert_redirected_to "/admin/articles/#{article.id}/edit"
  end

  test "create with invalid params re-renders new with 422" do
    post "/admin/articles", params: {article: {title: ""}}
    assert_response :unprocessable_entity
    assert_match "new", response.body.downcase
  end
end
