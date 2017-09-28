class Group < ApplicationRecord
  self.primary_key = "groupId"
  has_many :tasks
  has_many :phrases
  validates :groupId, presence: true
end
