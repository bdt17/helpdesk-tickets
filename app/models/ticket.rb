# app/models/ticket.rb
class Ticket < ApplicationRecord
  # Existing associations (e.g., belongs_to :user, :tech)
  enum status: { 
    new: 0,          # Fresh ticket
    in_progress: 1,  # Tech working on it
    on_hold: 2,      # Waiting for client info
    completed: 3     # Resolved
  }, _prefix: :status  # Allows status_new?, status_in_progress? helpers

  # Add validation
  validates :status, presence: true
end

after_update :log_status_change

private

def log_status_change
  if status_changed? && saved_change_to_status?
    TicketUpdate.create!(
      ticket: self,
      status: status,
      content: "Status changed to #{status.titleize}",
      user: current_user || # Handle in controller
    )
  end
end
