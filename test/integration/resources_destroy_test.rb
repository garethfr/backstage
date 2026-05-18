require "test_helper"

class ResourcesDestroyTest < ActionDispatch::IntegrationTest
  setup do
    set_current_user(mock_user(is_admin: true))
    Article.delete_all
    @article = Article.create!(title: "To Delete")
  end

  teardown { set_current_user(nil) }

  test "destroy deletes the record" do
    delete "/admin/articles/#{@article.id}"
    assert_equal 0, Article.count
  end

  test "destroy redirects to index" do
    delete "/admin/articles/#{@article.id}"
    assert_redirected_to "/admin/articles"
  end

  test "destroy returns 404 for unknown id" do
    delete "/admin/articles/999999"
    assert_response :not_found
  end
end
