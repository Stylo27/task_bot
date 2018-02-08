class User < ApplicationRecord
  has_many :tasks
  validates :id, uniqueness: true
  before_create do
    self.telegram_id = id
  end
end
