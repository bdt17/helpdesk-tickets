# A paid one-off purchase of extra tickets (see
# Webhooks::StripeController#handle_extra_tickets_purchase).
class TicketCreditPurchase < ApplicationRecord
  belongs_to :organization

  validates :stripe_checkout_session_id, presence: true, uniqueness: true
  validates :quantity, numericality: { only_integer: true, greater_than: 0 }
  validates :amount_cents, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
end
