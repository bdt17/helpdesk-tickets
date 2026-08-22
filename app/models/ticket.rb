class Ticket < ApplicationRecord
  CATEGORIES = %w[hardware software network access other].freeze

  belongs_to :user
  belongs_to :assignee, class_name: "User", optional: true

  enum :status, { open: "open", in_progress: "in_progress", resolved: "resolved", closed: "closed" }, default: :open
  enum :priority, { low: "low", medium: "medium", high: "high", critical: "critical" }, default: :medium

  validates :title, presence: true
  validates :category, inclusion: { in: CATEGORIES }, allow_nil: true

  scope :unresolved, -> { where.not(status: [:resolved, :closed]) }

  before_save :set_resolved_at, if: :will_save_change_to_status?

  private

  def set_resolved_at
    self.resolved_at = (resolved? || closed?) ? Time.current : nil
  end
end
