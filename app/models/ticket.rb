class Ticket < ApplicationRecord
  CATEGORIES = %w[hardware software network access other].freeze
  SLA_WINDOWS = { critical: 4.hours, high: 24.hours, medium: 3.days, low: 7.days }.freeze

  # Deliberately excludes SVG and HTML even though browsers can display
  # them - both can carry an embedded script, and this app serves
  # attachments back out to other users (staff viewing a client's
  # upload), so inline XSS via a "screenshot" is a real risk worth closing
  # off rather than a theoretical one.
  ALLOWED_ATTACHMENT_TYPES = %w[image/png image/jpeg image/gif image/webp application/pdf text/plain].freeze
  MAX_ATTACHMENTS = 5
  MAX_ATTACHMENT_SIZE = 10.megabytes

  belongs_to :user
  belongs_to :assignee, class_name: "User", optional: true
  has_many :comments, dependent: :destroy
  has_many_attached :attachments

  enum :status, { open: "open", in_progress: "in_progress", resolved: "resolved", closed: "closed" }, default: :open
  enum :priority, { low: "low", medium: "medium", high: "high", critical: "critical" }, default: :medium

  validates :title, presence: true
  validates :category, inclusion: { in: CATEGORIES }, allow_nil: true
  validates :satisfaction_rating, inclusion: { in: 1..5 }, allow_nil: true
  validate :priority_allowed_by_plan, if: :will_save_change_to_priority?
  validate :attachments_are_valid, if: -> { attachments.attached? }

  scope :unresolved, -> { where.not(status: [ :resolved, :closed ]) }
  scope :overdue, -> { unresolved.where.not(due_at: nil).where("due_at < ?", Time.current) }

  # The category <select> renders include_blank: true (see
  # tickets/_form.html.erb), which submits "" rather than omitting the
  # param entirely - without this, every ticket left uncategorized (the
  # case the AI-categorization hint text actively encourages) fails
  # validation with "Category is not included in the list" and can never
  # be created at all. Runs before the inclusion validation below, not
  # instead of it, so a real bogus value is still rejected.
  before_validation :nilify_blank_category

  before_save :set_resolved_at, if: :will_save_change_to_status?
  before_save :clear_escalation_on_reopen, if: :will_save_change_to_status?
  before_save :set_due_at, if: :will_save_change_to_priority?
  after_create_commit :enqueue_ai_categorization, if: -> { category.blank? }

  def overdue?
    due_at.present? && due_at < Time.current && !resolved? && !closed?
  end

  def rateable?
    (resolved? || closed?) && satisfaction_rating.nil?
  end

  private

  def nilify_blank_category
    self.category = nil if category.blank?
  end

  # Enforces the priority ceiling each plan tier's copy promises (see
  # Plan::Definition#max_priority) — e.g. only the Priority plan actually
  # unlocks "critical". Only fires when priority is actually being set
  # (see the `if:` above), so an unrelated edit — a status change, a
  # comment — never gets blocked retroactively by a ticket that predates
  # a downgrade, and only client-role tickets are plan-limited at all.
  def priority_allowed_by_plan
    return if user.nil?

    cap = user.max_ticket_priority
    priority_ranks = self.class.priorities.keys
    return if priority_ranks.index(priority) <= priority_ranks.index(cap)

    plan_name = user.plan_definition&.name || "current"
    errors.add(:priority, "of #{priority} exceeds the #{plan_name} plan's limit (up to #{cap})")
  end

  # Only checks the content type the browser declared on upload, not the
  # file's actual bytes - fine for a support tool where the worst case is
  # a client mislabeling their own file, but worth knowing if this ever
  # needs to withstand a deliberately malicious upload.
  def attachments_are_valid
    if attachments.count > MAX_ATTACHMENTS
      errors.add(:attachments, "cannot include more than #{MAX_ATTACHMENTS} files")
    end

    attachments.each do |attachment|
      unless ALLOWED_ATTACHMENT_TYPES.include?(attachment.content_type)
        errors.add(:attachments, "'#{attachment.filename}' must be an image, PDF, or plain text file")
      end

      if attachment.byte_size > MAX_ATTACHMENT_SIZE
        errors.add(:attachments, "'#{attachment.filename}' is too large (max #{MAX_ATTACHMENT_SIZE / 1.megabyte}MB)")
      end
    end
  end

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

  def enqueue_ai_categorization
    TicketCategorizationJob.perform_later(id)
  end
end
