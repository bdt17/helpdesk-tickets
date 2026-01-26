class SopTicket < ApplicationRecord
  enum :status, { Open: 0, "In Progress": 1, Resolved: 2 }
  enum :priority, { Low: 0, Medium: 1, High: 2, Critical: 3 }
end
