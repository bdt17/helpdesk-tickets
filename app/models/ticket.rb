class Ticket < ApplicationRecord
  enum :status, {
    new: 0,
    in_progress: 1,
    on_hold: 2,
    completed: 3
  }, prefix: true
end
