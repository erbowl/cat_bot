class Group < ApplicationRecord
  self.primary_key = "groupId"
  has_many :tasks
  has_many :phrases
  accepts_nested_attributes_for :tasks, allow_destroy: true
  accepts_nested_attributes_for :phrases, allow_destroy: true
  validates :groupId, presence: true
end
