require "test_helper"

# Simulate a host-app subclass registered for a model.
module Backstage
  class ArticlesController < ResourcesController
    def publish
      record = Article.find(params[:id])
      record.update!(title: "[Published] #{record.title}")
      redirect_to resources_path(resource: params[:resource])
    end
  end
end

class CustomActionsTest < ActionDispatch::IntegrationTest
  setup do
    set_current_user(mock_user(is_admin: true))
    Article.delete_all
    @article = Article.create!(title: "Draft Post")
  end

  teardown { set_current_user(nil) }

  test "custom action dispatches to host subclass method" do
    post "/admin/articles/#{@article.id}/publish"
    assert_redirected_to "/admin/articles"
    assert_equal "[Published] Draft Post", @article.reload.title
  end

  test "custom action returns 404 for unknown resource" do
    post "/admin/ghosts/1/publish"
    assert_response :not_found
  end
end
