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

  test "inherited CRUD action cannot be dispatched via custom action route even with a custom controller" do
    # destroy is inherited on ArticlesController but not defined directly on it —
    # instance_methods(false) must exclude it so it cannot be called via the custom action route
    post "/admin/articles/#{@article.id}/destroy"
    assert_response :internal_server_error
    assert Article.exists?(@article.id), "record must not be deleted via the custom action route"
  end

  test "custom action route returns 500 when no host subclass exists for the resource" do
    tag = Tag.create!(name: "release-test-tag")
    post "/admin/tags/#{tag.id}/some_custom_action"
    assert_response :internal_server_error
  ensure
    Tag.delete_all
  end
end
