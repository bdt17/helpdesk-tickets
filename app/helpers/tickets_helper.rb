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

  URGENCY_LABELS = {
    "low" => "Low - a question or minor annoyance",
    "medium" => "Normal - something isn't working right",
    "high" => "High - I can't get my work done",
    "critical" => "Business down - nobody can work"
  }.freeze

  # [label, value] pairs for the new-ticket urgency select, capped at what
  # the filer's plan allows (User#max_ticket_priority) so nobody is offered
  # an option the validation would then reject. Defaults to "medium".
  def urgency_options_for(user)
    allowed = Ticket.priorities.keys
    allowed = allowed.first(allowed.index(user.max_ticket_priority) + 1)
    allowed.map do |priority|
      window = Ticket::SLA_WINDOWS.fetch(priority.to_sym).inspect
      [ "#{URGENCY_LABELS.fetch(priority)} (response within #{window})", priority ]
    end
  end

  def ticket_status_badge_class(status)
    STATUS_BADGE_CLASSES.fetch(status.to_s, "bg-secondary")
  end

  def ticket_priority_badge_class(priority)
    PRIORITY_BADGE_CLASSES.fetch(priority.to_s, "bg-secondary")
  end
end
