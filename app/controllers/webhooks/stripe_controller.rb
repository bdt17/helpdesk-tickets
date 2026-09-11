module Webhooks
  # The single source of truth for an organization's subscription state
  # (Phase 12 moved billing off the individual User and onto Organization,
  # so a subscription can cover multiple seats). Stripe calls this from
  # its own servers (no session/cookie), so it's outside Devise/Pundit
  # entirely and authenticates the request via Stripe's signature on the
  # payload instead of a login.
  class StripeController < ActionController::Base
    skip_before_action :verify_authenticity_token

    def create
      event = verify_event!
      return head :bad_request unless event

      case event.type
      when "checkout.session.completed"
        handle_checkout_completed(event.data.object)
      when "customer.subscription.updated", "customer.subscription.deleted"
        sync_subscription(event.data.object)
      end

      head :ok
    end

    private

    def verify_event!
      payload = request.body.read
      sig_header = request.headers["Stripe-Signature"]
      secret = ENV["STRIPE_WEBHOOK_SECRET"]
      return nil if secret.blank?

      Stripe::Webhook.construct_event(payload, sig_header, secret)
    rescue JSON::ParserError, Stripe::SignatureVerificationError
      nil
    end

    def handle_checkout_completed(session)
      return if session.subscription.blank?

      subscription = Stripe::Subscription.retrieve(session.subscription)
      sync_subscription(subscription)
    end

    def sync_subscription(subscription)
      organization = Organization.find_by(stripe_customer_id: subscription.customer)
      return unless organization # unknown customer — nothing in our system to update

      price_id = subscription.items.data.first&.price&.id
      organization.update!(
        stripe_subscription_id: subscription.id,
        subscription_status: subscription.status,
        plan: Plan.key_for_price_id(price_id)
      )
    end
  end
end
