require "test_helper"

module Backstage
  class ArticlesController < ResourcesController
    def archive
      @record = Article.find(params[:id])
      respond_with_row_removed
    end

    def flag
      @record = Article.find(params[:id])
      respond_with_success("Flagged successfully")
    end
  end
end

class TurboStreamTest < ActionDispatch::IntegrationTest
  setup do
    set_current_user(mock_user(is_admin: true))
    Article.delete_all
    @article = Article.create!(title: "Turbo Test")
  end

  teardown { set_current_user(nil) }

  test "respond_with_row_removed returns turbo-stream remove" do
    post "/admin/articles/#{@article.id}/archive",
      headers: {"Accept" => "text/vnd.turbo-stream.html"}
    assert_response :success
    assert_match "turbo-stream", response.body
    assert_match "remove", response.body
    assert_match "articles_#{@article.id}_row", response.body
  end

  test "respond_with_success returns turbo-stream with message" do
    post "/admin/articles/#{@article.id}/flag",
      headers: {"Accept" => "text/vnd.turbo-stream.html"}
    assert_response :success
    assert_match "turbo-stream", response.body
    assert_match "Flagged successfully", response.body
  end
end
