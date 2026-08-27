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
  end
end
