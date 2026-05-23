require "test_helper"

class ResourcesEditTest < ActionDispatch::IntegrationTest
  setup do
    set_current_user(mock_user(is_admin: true))
    Article.delete_all
    @article = Article.create!(title: "Original")
  end

  teardown { set_current_user(nil) }

  test "edit renders successfully" do
    get "/admin/articles/#{@article.id}/edit"
    assert_response :success
    assert_match "Original", response.body
  end

  test "edit returns 404 for unknown id" do
    get "/admin/articles/999999/edit"
    assert_response :not_found
  end

  test "update with valid params redirects to index" do
    patch "/admin/articles/#{@article.id}", params: {article: {title: "Updated"}}
    assert_redirected_to "/admin/articles"
    assert_equal "Updated", @article.reload.title
  end

  test "update with invalid params re-renders edit with 422" do
    patch "/admin/articles/#{@article.id}", params: {article: {title: ""}}
    assert_response :unprocessable_entity
    assert_match "edit", response.body.downcase
  end

  test "update works when resource param is singular-capitalized (e.g. /admin/Article/:id)" do
    patch "/admin/Article/#{@article.id}", params: {article: {title: "Updated via capitalized route"}}
    assert_redirected_to "/admin/Article"
    assert_equal "Updated via capitalized route", @article.reload.title
  end
end
