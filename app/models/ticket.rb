class Ticket < ApplicationRecord
  CATEGORIES = %w[hardware software network access other].freeze
  SLA_WINDOWS = { critical: 4.hours, high: 24.hours, medium: 3.days, low: 7.days }.freeze

  belongs_to :user
  belongs_to :assignee, class_name: "User", optional: true
  has_many :comments, dependent: :destroy

  enum :status, { open: "open", in_progress: "in_progress", resolved: "resolved", closed: "closed" }, default: :open
  enum :priority, { low: "low", medium: "medium", high: "high", critical: "critical" }, default: :medium

  validates :title, presence: true
  validates :category, inclusion: { in: CATEGORIES }, allow_nil: true

  scope :unresolved, -> { where.not(status: [ :resolved, :closed ]) }
  scope :overdue, -> { unresolved.where.not(due_at: nil).where("due_at < ?", Time.current) }

  before_save :set_resolved_at, if: :will_save_change_to_status?
  before_save :clear_escalation_on_reopen, if: :will_save_change_to_status?
  before_save :set_due_at, if: :will_save_change_to_priority?

  def overdue?
    due_at.present? && due_at < Time.current && !resolved? && !closed?
  end

  private

  def set_resolved_at
    self.resolved_at = (resolved? || closed?) ? Time.current : nil
  end

  def clear_escalation_on_reopen
    old_status, new_status = status_change_to_be_saved
    was_closed = %w[resolved closed].include?(old_status)
    reopening = %w[open in_progress].include?(new_status)
    self.escalated_at = nil if was_closed && reopening
  end

  def set_due_at
    self.due_at = Time.current + SLA_WINDOWS.fetch(priority.to_sym)
  end
end
