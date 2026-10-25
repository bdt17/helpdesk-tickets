# Failed-payment notices (see Webhooks::StripeController#handle_payment_failed).
# `details` carries the bits of the Stripe invoice worth showing, as plain
# values so the job serializes cleanly.
class BillingMailer < ApplicationMailer
  helper_method :formatted_amount, :next_attempt_on

  def payment_failed(organization, recipient, details)
    @organization = organization
    @details = details.symbolize_keys

    mail(to: recipient.email, subject: "Action needed: your Thomas IT payment didn't go through")
  end

  def payment_failed_staff_alert(organization, recipient, details)
    @organization = organization
    @details = details.symbolize_keys

    mail(to: recipient.email, subject: "Payment failed: #{organization.name} (#{formatted_amount})")
  end

  private

  def formatted_amount
    amount = @details[:amount_due].to_i / 100.0
    currency = @details[:currency].to_s.upcase
    currency == "USD" || currency.empty? ? format("$%.2f", amount) : format("%.2f %s", amount, currency)
  end

  def next_attempt_on
    timestamp = @details[:next_payment_attempt]
    Time.zone.at(timestamp.to_i).strftime("%B %-d, %Y") if timestamp.present?
  end
end
