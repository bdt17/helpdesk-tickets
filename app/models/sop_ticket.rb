class SopTicket < ApplicationRecord
  enum :status, { open: 0, in_progress: 1, resolved: 2 }
  enum :priority, { low: 0, medium: 1, high: 2, critical: 3 }
end
