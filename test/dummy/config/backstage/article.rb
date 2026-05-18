Backstage.resource(:Article) do |c|
  c.display_column :title
  c.field :cover_url, as: :image_url
  c.has_many :tags, display_column: :name
  c.sidebar do |s|
    s.link "All tags", "/admin/tags"
  end
end
