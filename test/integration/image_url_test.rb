require "test_helper"

class ImageUrlTest < ActionDispatch::IntegrationTest
  setup do
    set_current_user(mock_user(is_admin: true))
    Article.delete_all
    @article = Article.create!(title: "https://example.com/pic.jpg")
  end

  teardown { set_current_user(nil) }

  test "image_url field renders img tag and editable text input on edit" do
    with_registry do
      get "/admin/articles/#{@article.id}/edit"
      assert_response :success
      assert_match "<img", response.body
      assert_match "https://example.com/pic.jpg", response.body
      assert_match 'type="text"', response.body
    end
  end

  private

  def with_registry
    config = Backstage::AutoDiscovery.build(Article)
    config.field :title, as: :image_url
    orig = Backstage.registry
    Backstage.registry = Backstage::Registry.new
    Backstage.registry.register("Article", config)
    yield
  ensure
    Backstage.registry = orig
  end
end
