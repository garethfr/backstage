require "test_helper"

class SortableColumnsTest < ActionDispatch::IntegrationTest
  setup do
    set_current_user(mock_user(is_admin: true))
    Article.delete_all
    Article.create!(title: "Bravo")
    Article.create!(title: "Alpha")
    Article.create!(title: "Charlie")
  end

  teardown { set_current_user(nil) }

  test "default order returns records in default DB order" do
    get "/admin/articles"
    assert_response :success
  end

  test "sort ascending by title" do
    get "/admin/articles", params: {sort: "title", dir: "asc"}
    assert_response :success
    assert_match(/Alpha.*Bravo.*Charlie/m, response.body)
  end

  test "sort descending by title" do
    get "/admin/articles", params: {sort: "title", dir: "desc"}
    assert_response :success
    assert_match(/Charlie.*Bravo.*Alpha/m, response.body)
  end

  test "invalid sort column is ignored" do
    get "/admin/articles", params: {sort: "malicious_column; DROP TABLE articles", dir: "asc"}
    assert_response :success
  end

  test "index view includes sort links in column headers" do
    get "/admin/articles"
    assert_match "sort=title", response.body
  end
end
