ActiveRecord::Schema[8.0].define(version: 2) do
  create_table :articles, force: true do |t|
    t.string :title
    t.text :body
    t.integer :status, default: 0
    t.datetime :published_at
    t.integer :view_count, default: 0
    t.boolean :featured, default: false
    t.string :cover_url
    t.timestamps
  end

  create_table :tags, force: true do |t|
    t.string :name
    t.timestamps
  end

  create_table :articles_tags, force: true, id: false do |t|
    t.integer :article_id
    t.integer :tag_id
  end
end
