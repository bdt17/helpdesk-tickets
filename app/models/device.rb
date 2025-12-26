class Device < ApplicationRecord
  scope :available, -> { where(status: 'available') }
end
