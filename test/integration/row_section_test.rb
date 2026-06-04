require "test_helper"

class RowSectionTest < ActionDispatch::IntegrationTest
  setup do
    set_current_user(mock_user(is_admin: true))
    Article.delete_all
    @article = Article.create!(title: "Original", body: "Body text")
    @orig_registry = Backstage.registry
  end

  teardown do
    Backstage.registry = @orig_registry
    set_current_user(nil)
  end

  # --- new page container rendering ---

  test "new page renders row without a spurious container label" do
    build_config { |c| c.row(:title, :body) }
    get "/admin/articles/new"
    assert_response :success
    assert_match 'class="grid"', response.body
    assert_no_match 'for="article_row_', response.body
  end

  test "new page renders section without a spurious container label" do
    build_config { |c| c.section("Content") { c.field(:title) } }
    get "/admin/articles/new"
    assert_response :success
    assert_match "<details", response.body
    assert_no_match 'for="article_section_', response.body
  end

  # --- edit page row rendering ---

  test "edit page renders row fields inside a grid div" do
    build_config { |c| c.row(:title, :body) }
    get "/admin/articles/#{@article.id}/edit"
    assert_response :success
    assert_match 'class="grid"', response.body
  end

  test "row renders both field inputs" do
    build_config { |c| c.row(:title, :body) }
    get "/admin/articles/#{@article.id}/edit"
    assert_match "article[title]", response.body
    assert_match "article[body]", response.body
  end

  # --- section rendering ---

  test "edit page renders section as a details element with summary" do
    build_config { |c| c.section("Content") { c.row(:title, :body) } }
    get "/admin/articles/#{@article.id}/edit"
    assert_match "<details", response.body
    assert_match "<summary", response.body
    assert_match "Content", response.body
  end

  test "section without collapsed renders with open attribute" do
    build_config { |c| c.section("Content") { c.field(:title) } }
    get "/admin/articles/#{@article.id}/edit"
    assert_match "<details open", response.body
  end

  test "section with collapsed: true renders without open attribute" do
    build_config { |c| c.section("Content", collapsed: true) { c.field(:title) } }
    get "/admin/articles/#{@article.id}/edit"
    assert_match "<details", response.body
    assert_no_match "<details open", response.body
  end

  # --- params / update ---

  test "update saves a field nested inside a row" do
    build_config { |c| c.row(:title, :body) }
    patch "/admin/articles/#{@article.id}", params: {article: {title: "Row Updated"}}
    assert_redirected_to "/admin/articles/#{@article.id}/edit"
    assert_equal "Row Updated", @article.reload.title
  end

  test "update saves a field nested inside a section" do
    build_config { |c| c.section("Details") { c.field(:title) } }
    patch "/admin/articles/#{@article.id}", params: {article: {title: "Section Updated"}}
    assert_redirected_to "/admin/articles/#{@article.id}/edit"
    assert_equal "Section Updated", @article.reload.title
  end

  test "update saves a field in a row nested inside a section" do
    build_config { |c| c.section("Details") { c.row(:title, :body) } }
    patch "/admin/articles/#{@article.id}", params: {article: {title: "Nested Row Updated"}}
    assert_redirected_to "/admin/articles/#{@article.id}/edit"
    assert_equal "Nested Row Updated", @article.reload.title
  end

  private

  def build_config(&block)
    config = Backstage::AutoDiscovery.build(Article)
    block.call(config)
    Backstage.registry = Backstage::Registry.new
    Backstage.registry.register("Article", config)
    config
  end
end
