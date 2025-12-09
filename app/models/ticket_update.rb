class TicketUpdate < ApplicationRecord
  belongs_to :ticket
  belongs_to :user   # Who made the update (tech/client)
  
  enum status: { 
    new: 0, in_progress: 1, on_hold: 2, completed: 3 
  }, _prefix: :status
end
