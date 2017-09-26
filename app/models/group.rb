class Group < ApplicationRecord
  self.primary_key = "groupId"
  has_many :tasks
  
  validates :groupId, presence: true
end
