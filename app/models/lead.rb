# A sales inquiry from the public homepage's contact form - someone who
# hasn't signed up yet. Saved to the database rather than only emailed,
# so no inquiry is lost if outgoing mail isn't configured (or lands in
# spam); staff work them from /leads.
class Lead < ApplicationRecord
  STATUSES = %w[new contacted won lost].freeze

  validates :name, presence: true, length: { maximum: 100 }
  validates :email, presence: true, length: { maximum: 255 }, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :company, :phone, length: { maximum: 100 }
  validates :message, length: { maximum: 5000 }
  validates :status, inclusion: { in: STATUSES }

  normalizes :email, with: ->(email) { email.strip.downcase }

  scope :open_leads, -> { where(status: %w[new contacted]) }
end
