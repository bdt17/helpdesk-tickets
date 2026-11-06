# The numbers behind the monthly "here's what we did for you" email
# (MonthlyClientReportJob): one organization's tickets for one calendar
# month. A client who never sees what their plan does for them is the
# client most likely to cancel it.
class MonthlyClientReport
  attr_reader :organization, :month

  def initialize(organization, month)
    @organization = organization
    @month = month.beginning_of_month
  end

  def period
    month.all_month
  end

  def stats
    @stats ||= begin
      tickets = Ticket.where(user: organization.users)
      filed = tickets.where(created_at: period)
      resolved = tickets.where(status: %i[resolved closed], resolved_at: period)
      hours = resolved.map { |ticket| (ticket.resolved_at - ticket.created_at) / 1.hour }
      with_sla = resolved.where.not(due_at: nil)
      rated = resolved.where.not(satisfaction_rating: nil)

      {
        month_name: month.strftime("%B %Y"),
        filed: filed.count,
        resolved: resolved.count,
        avg_resolution_hours: hours.any? ? (hours.sum / hours.size).round(1) : nil,
        sla_met_percent: with_sla.any? ? (with_sla.count { |t| t.resolved_at <= t.due_at } * 100.0 / with_sla.size).round : nil,
        csat_average: rated.any? ? rated.average(:satisfaction_rating).round(1).to_f : nil,
        still_open: tickets.unresolved.count,
        technician_minutes: TimeEntry.where(ticket: tickets, worked_on: period).sum(:minutes),
        by_category: filed.where.not(category: nil).group(:category).count.sort_by { |_, count| -count }.to_h
      }
    end
  end
end
