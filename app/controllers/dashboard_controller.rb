class DashboardController < ApplicationController
  before_action :authenticate_user!

  def index
    @scope = policy_scope(Ticket)
    @total = @scope.count
    @by_status = @scope.group(:status).count
    @by_priority = @scope.group(:priority).count
    @overdue = @scope.overdue.order(:due_at)
    @recent = @scope.order(created_at: :desc).limit(10)

    if current_user.agent? || current_user.admin?
      @unassigned_count = @scope.unresolved.where(assignee_id: nil).count
      # Critical first, then high; oldest deadline first within each.
      @urgent = @scope.unresolved.where(priority: [ :critical, :high ])
        .includes(:assignee, user: :organization)
        .order(Arel.sql("CASE priority WHEN 'critical' THEN 0 ELSE 1 END"), :due_at)
        .limit(20)
    end
  end
end
