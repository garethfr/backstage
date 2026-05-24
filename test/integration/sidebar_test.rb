require "test_helper"

class SidebarTest < ActionDispatch::IntegrationTest
  setup do
    set_current_user(mock_user(is_admin: true))
    Article.delete_all
    @article = Article.create!(title: "Sidebar Test")
    @orig_registry = Backstage.registry
  end

  teardown do
    set_current_user(nil)
    Backstage.registry = @orig_registry
  end

  test "sidebar static links render on edit page" do
    config = Backstage::AutoDiscovery.build(Article)
    config.sidebar do |s|
      s.link "Go to Articles", "/admin/articles"
    end
    Backstage.registry = Backstage::Registry.new
    Backstage.registry.register("Article", config)

    get "/admin/articles/#{@article.id}/edit"
    assert_response :success
    assert_match "<aside", response.body
    assert_match "Go to Articles", response.body
    assert_match "/admin/articles", response.body
  end

  test "sidebar dynamic link evaluated with record" do
    config = Backstage::AutoDiscovery.build(Article)
    config.sidebar do |s|
      s.link "View", ->(record) { "/admin/articles/#{record.id}" }
    end
    Backstage.registry = Backstage::Registry.new
    Backstage.registry.register("Article", config)

    get "/admin/articles/#{@article.id}/edit"
    assert_response :success
    assert_match "/admin/articles/#{@article.id}", response.body
  end

  test "no sidebar when no links configured" do
    config = Backstage::AutoDiscovery.build(Article)
    Backstage.registry = Backstage::Registry.new
    Backstage.registry.register("Article", config)

    get "/admin/articles/#{@article.id}/edit"
    assert_response :success
    assert_no_match "<aside", response.body
  end

  test "sidebar with proc link does not crash on index page where record is nil" do
    config = Backstage::AutoDiscovery.build(Article)
    config.sidebar do |s|
      s.link "View", ->(record) { "/articles/#{record.id}" }
    end
    Backstage.registry = Backstage::Registry.new
    Backstage.registry.register("Article", config)

    get "/admin/articles"
    assert_response :success
    assert_no_match "<aside", response.body
  end

  test "sidebar is hidden on new record page" do
    config = Backstage::AutoDiscovery.build(Article)
    config.sidebar do |s|
      s.link "View", ->(record) { "/articles/#{record.id}" }
    end
    Backstage.registry = Backstage::Registry.new
    Backstage.registry.register("Article", config)

    get "/admin/articles/new"
    assert_response :success
    assert_no_match "<aside", response.body
  end
end
