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

    if current_user.admin?
      @revenue = revenue_summary
      @health = system_health
      @profit_month = params[:month] == "last" ? 1.month.ago.to_date : Date.current
      @profitability = client_profitability(@profit_month.all_month)
    end

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

  private

  # Business-owner view (admin only): who's paying, on what, and roughly
  # how much that's worth a month.
  def revenue_summary
    paying = Organization.where(subscription_status: %w[active trialing])
    by_plan = paying.group(:plan).count
    # Annual subscribers count at their monthly equivalent (yearly price / 12).
    mrr = paying.group(:plan, :billing_interval).count.sum do |(key, interval), count|
      Plan.monthly_revenue(key, interval) * count
    end.round
    clients = User.client

    {
      mrr: mrr,
      active: paying.where(subscription_status: "active").count,
      annual: paying.where(billing_interval: "year").count,
      trialing: paying.where(subscription_status: "trialing").count,
      past_due: Organization.where(subscription_status: %w[past_due unpaid]).count,
      payment_problems: Organization.where.not(payment_failed_at: nil)
                                    .or(Organization.where(subscription_status: %w[past_due unpaid]))
                                    .order(payment_failed_at: :desc).includes(:users).to_a,
      by_plan: by_plan,
      extra_ticket_revenue_30_days: TicketCreditPurchase.where(created_at: 30.days.ago..).sum(:amount_cents) / 100.0,
      clients_total: clients.count,
      clients_new_30_days: clients.where(created_at: 30.days.ago..).count,
      clients_never_subscribed: clients.where(organization_id: nil).count
    }
  end

  # Logged technician time vs. plan revenue for each client in one month
  # (admin only), lowest revenue-per-hour first - the clients a plan's
  # price isn't covering. STAFF_HOURLY_COST (optional, whole dollars) adds
  # an estimated profit column. Revenue is the listed plan price, like the
  # MRR estimate above; extra-ticket purchases aren't included.
  def client_profitability(period)
    hourly_cost = ENV["STAFF_HOURLY_COST"].to_f
    minutes_by_org = Hash.new(0)
    TimeEntry.where(worked_on: period).includes(ticket: { user: :organization }).find_each do |entry|
      minutes_by_org[entry.ticket.user&.organization] += entry.minutes
    end
    organizations = (minutes_by_org.keys.compact + Organization.where(subscription_status: %w[active trialing past_due]).to_a).uniq

    rows = organizations.map do |org|
      revenue = org.subscribed? ? Plan.monthly_revenue(org.plan, org.billing_interval) : 0
      minutes = minutes_by_org[org]
      hours = minutes / 60.0
      {
        organization: org,
        revenue: revenue,
        minutes: minutes,
        per_hour: minutes.positive? ? (revenue / hours).round : nil,
        profit: hourly_cost.positive? ? (revenue - hours * hourly_cost).round : nil
      }
    end

    {
      rows: rows.sort_by { |row| [ row[:per_hour] ? 0 : 1, row[:per_hour].to_i ] },
      unaffiliated_minutes: minutes_by_org[nil],
      total_minutes: minutes_by_org.values.sum,
      hourly_cost: hourly_cost.positive? ? hourly_cost : nil
    }
  end

  # Everything production needs configured outside the code, in one
  # place - each of these has silently been missing at some point.
  def system_health
    {
      "Background jobs running (emails, AI, SLA escalation)" => jobs_running?,
      "Outgoing email configured (SMTP_ADDRESS)" => ENV["SMTP_ADDRESS"].present?,
      "Attachments on a persistent disk (ACTIVE_STORAGE_ROOT)" => ENV["ACTIVE_STORAGE_ROOT"].present?,
      "Stripe keys and all three plan prices set" => ENV["STRIPE_SECRET_KEY"].present? && Plan::ALL.all? { |plan| Plan.price_id_for(plan.key).present? },
      "Stripe webhook secret set (STRIPE_WEBHOOK_SECRET)" => ENV["STRIPE_WEBHOOK_SECRET"].present?,
      "Stripe in live mode (real payments)" => ENV["STRIPE_SECRET_KEY"].to_s.start_with?("sk_live_", "rk_live_"),
      "Error alerts enabled (SENTRY_DSN)" => ENV["SENTRY_DSN"].present?,
      "AI categorization enabled (ANTHROPIC_API_KEY)" => TicketCategorizer.configured?
    }
  end

  def jobs_running?
    SolidQueue::Process.where(last_heartbeat_at: 5.minutes.ago..).exists?
  rescue ActiveRecord::ActiveRecordError
    false
  end
end
