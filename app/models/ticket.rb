class Ticket < ApplicationRecord
  scope :open, -> { where(status: 'open') }
  scope :for_tech, ->(_user) { all }
end
