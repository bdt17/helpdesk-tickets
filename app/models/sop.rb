class Sop < ApplicationRecord
  scope :recent, -> { order(created_at: :desc).limit(5) }
end
