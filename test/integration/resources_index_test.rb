require "test_helper"

class ResourcesIndexTest < ActionDispatch::IntegrationTest
  setup do
    set_current_user(mock_user(is_admin: true))
    Article.delete_all
  end

  teardown { set_current_user(nil) }

  test "index renders successfully" do
    get "/admin/articles"
    assert_response :success
  end

  test "index renders all records when count <= per_page" do
    Article.create!(title: "Alpha")
    Article.create!(title: "Beta")
    get "/admin/articles"
    assert_response :success
    assert_match "Alpha", response.body
    assert_match "Beta", response.body
  end

  test "pagination: first page shows per_page records and not the rest" do
    per_page = Backstage.configuration.per_page
    (per_page + 2).times { |i| Article.create!(title: "Article #{i.to_s.rjust(3, "0")}") }
    get "/admin/articles"
    articles_on_page = Article.order(:id).first(per_page)
    remaining = Article.order(:id).last(2)
    articles_on_page.each { |a| assert_match a.title, response.body }
    remaining.each { |a| assert_no_match a.title, response.body }
  end

  test "pagination: page 2 shows remaining records" do
    per_page = Backstage.configuration.per_page
    (per_page + 2).times { |i| Article.create!(title: "Article #{i.to_s.rjust(3, "0")}") }
    get "/admin/articles", params: {page: 2}
    remaining = Article.order(:id).last(2)
    remaining.each { |a| assert_match a.title, response.body }
    first_article = Article.order(:id).first
    assert_no_match first_article.title, response.body
  end

  test "pagination shows first and last page links when there are many pages" do
    per_page = Backstage.configuration.per_page
    (per_page * 15).times { |i| Article.create!(title: "Article #{i}") }
    get "/admin/articles", params: {page: 8}
    assert_match "page=1", response.body
    assert_match "page=15", response.body
  end

  test "pagination shows only 5 pages around current page" do
    per_page = Backstage.configuration.per_page
    (per_page * 15).times { |i| Article.create!(title: "Article #{i}") }
    get "/admin/articles", params: {page: 8}
    assert_match "page=6", response.body
    assert_match "page=10", response.body
    assert_no_match "page=5\"", response.body
    assert_no_match "page=11\"", response.body
  end

  test "pagination with few pages does not render links below 1 or above total" do
    per_page = Backstage.configuration.per_page
    (per_page * 3).times { |i| Article.create!(title: "Article #{i}") }
    get "/admin/articles", params: {page: 2}
    assert_no_match "page=0", response.body
    assert_no_match "page=-1", response.body
    assert_no_match "page=4", response.body
    assert_no_match "page=5", response.body
  end

  test "search filters by display_column" do
    Article.create!(title: "Alpha")
    Article.create!(title: "Beta")
    Article.create!(title: "alphabetical")
    get "/admin/articles", params: {q: "alpha"}
    assert_match "Alpha", response.body
    assert_match "alphabetical", response.body
    assert_no_match "Beta", response.body
  end

  test "returns 404 for unregistered resource" do
    get "/admin/ghosts"
    assert_response :not_found
  end
end
