require "test_helper"

ActiveRecord::Schema.define do
  create_table :backstage_thumb_photos, force: true do |t|
    t.string :url
    t.string :title
    t.integer :backstage_thumb_article_id
    t.timestamps
  end
  create_table :backstage_thumb_articles, force: true do |t|
    t.string :title
    t.timestamps
  end
end

class BackstageThumbPhoto < ApplicationRecord
  self.table_name = "backstage_thumb_photos"
  belongs_to :backstage_thumb_article
end

class BackstageThumbArticle < ApplicationRecord
  self.table_name = "backstage_thumb_articles"
  has_many :backstage_thumb_photos
  validates :title, presence: true
end

class ThumbnailsTest < ActionDispatch::IntegrationTest
  setup do
    set_current_user(mock_user(is_admin: true))
    BackstageThumbPhoto.delete_all
    BackstageThumbArticle.delete_all

    @article = BackstageThumbArticle.create!(title: "Gallery")
    @photo1 = BackstageThumbPhoto.create!(
      url: "https://example.com/a.jpg", title: "Photo A",
      backstage_thumb_article: @article
    )
    @photo2 = BackstageThumbPhoto.create!(
      url: "https://example.com/b.jpg", title: "Photo B",
      backstage_thumb_article: @article
    )

    photo_config = Backstage::AutoDiscovery.build(BackstageThumbPhoto)
    article_config = Backstage::AutoDiscovery.build(BackstageThumbArticle)
    article_config.has_many :backstage_thumb_photos, as: :thumbnails, image_col: :url

    @orig_registry = Backstage.registry
    Backstage.registry = Backstage::Registry.new
    Backstage.registry.register("BackstageThumbPhoto", photo_config)
    Backstage.registry.register("BackstageThumbArticle", article_config)
  end

  teardown do
    Backstage.registry = @orig_registry
    set_current_user(nil)
  end

  test "edit renders figure elements for thumbnails" do
    get "/admin/backstage_thumb_articles/#{@article.id}/edit"
    assert_response :success
    assert_match "<figure", response.body
    assert_match "https://example.com/a.jpg", response.body
    assert_match "https://example.com/b.jpg", response.body
  end

  test "thumbnails link to photo edit page" do
    get "/admin/backstage_thumb_articles/#{@article.id}/edit"
    assert_match "/admin/backstage_thumb_photos/#{@photo1.id}/edit", response.body
  end
end
