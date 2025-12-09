class Ticket < ApplicationRecord
  enum :status, {
    new: 0,
    in_progress: 1,
    on_hold: 2,
    completed: 3
  }, prefix: true

  # ← ADD THESE QUALITY FEATURES HERE:
  accepts_nested_attributes_for :updates
end

