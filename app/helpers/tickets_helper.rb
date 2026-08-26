module TicketsHelper
  STATUS_BADGE_CLASSES = {
    "open" => "bg-primary",
    "in_progress" => "bg-info text-dark",
    "resolved" => "bg-success",
    "closed" => "bg-secondary"
  }.freeze

  PRIORITY_BADGE_CLASSES = {
    "low" => "bg-secondary",
    "medium" => "bg-info text-dark",
    "high" => "bg-warning text-dark",
    "critical" => "bg-danger"
  }.freeze

  def ticket_status_badge_class(status)
    STATUS_BADGE_CLASSES.fetch(status.to_s, "bg-secondary")
  end

  def ticket_priority_badge_class(priority)
    PRIORITY_BADGE_CLASSES.fetch(priority.to_s, "bg-secondary")
  end
end
