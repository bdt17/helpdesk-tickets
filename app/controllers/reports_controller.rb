class ReportsController < ApplicationController
  before_action :authenticate_user!
  before_action :require_staff!

  def index
    scope = policy_scope(Ticket)
    @total = scope.count
    @by_status = scope.group(:status).count
    @by_priority = scope.group(:priority).count
    @by_category = scope.group(:category).count
    @overdue_count = scope.overdue.count
    @resolved_last_30_days = scope.where(status: [ :resolved, :closed ]).where("resolved_at > ?", 30.days.ago).count

    rated = scope.where.not(satisfaction_rating: nil)
    @csat_responses = rated.count
    @csat_average = rated.average(:satisfaction_rating)&.round(2)

    # Computed in Ruby, not SQL, since resolution time is a plain
    # (resolved_at - created_at) subtraction and this app runs SQLite in
    # dev/test but PostgreSQL in production - no single date-arithmetic
    # function works unmodified on both.
    @agent_performance = User.agent.order(:email).map do |agent|
      resolved = scope.where(assignee: agent, status: [ :resolved, :closed ]).where.not(resolved_at: nil)
      hours = resolved.map { |ticket| (ticket.resolved_at - ticket.created_at) / 1.hour }

      {
        agent: agent,
        open: scope.where(assignee: agent).unresolved.count,
        resolved: resolved.count,
        avg_resolution_hours: hours.any? ? (hours.sum / hours.size).round(1) : nil
      }
    end
  end
end
