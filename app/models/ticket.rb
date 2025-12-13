class Ticket < ApplicationRecord
  belongs_to :user
  belongs_to :project, optional: true
  enum :status, { New: 0, "In Progress": 1, Resolved: 2 }, default: :new
  validates :title, :description, presence: true
end
