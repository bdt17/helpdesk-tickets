class Ticket < ApplicationRecord
  scope :open, -> { where(status: 'open') }
  scope :for_tech, ->(user) { all }
end
