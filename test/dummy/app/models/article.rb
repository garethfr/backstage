class Article < ApplicationRecord
  has_and_belongs_to_many :tags
  enum :status, {draft: 0, published: 1, archived: 2}
  validates :title, presence: true
end
