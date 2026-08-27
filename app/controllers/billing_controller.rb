# Client-facing subscription management. Actual subscription state is only
# ever written by Webhooks::StripeController — this controller only ever
# *asks* Stripe to start a checkout or open the billing portal; it never
# marks a user as subscribed itself, so a client can't grant themselves a
# paid plan by hitting these actions directly.
class BillingController < ApplicationController
  before_action :authenticate_user!
  before_action :require_client!

  def show
    @plans = Plan::ALL
  end

  def checkout
    plan = Plan.find(params[:plan])
    return redirect_to billing_path, alert: "Unknown plan." unless plan && Plan.price_id_for(plan.key).present?

    ensure_stripe_customer!

    session = Stripe::Checkout::Session.create(
      customer: current_user.stripe_customer_id,
      client_reference_id: current_user.id.to_s,
      mode: "subscription",
      line_items: [ { price: Plan.price_id_for(plan.key), quantity: 1 } ],
      success_url: billing_success_url,
      cancel_url: billing_url
    )

    redirect_to session.url, allow_other_host: true
  rescue Stripe::StripeError => e
    redirect_to billing_path, alert: "Couldn't start checkout: #{e.message}"
  end

  def success
    flash[:notice] = "Thanks! Your subscription is being set up — this can take a few seconds to confirm."
    redirect_to billing_path
  end

  def portal
    return redirect_to billing_path, alert: "No billing account on file yet." if current_user.stripe_customer_id.blank?

    session = Stripe::BillingPortal::Session.create(
      customer: current_user.stripe_customer_id,
      return_url: billing_url
    )

    redirect_to session.url, allow_other_host: true
  rescue Stripe::StripeError => e
    redirect_to billing_path, alert: "Couldn't open billing portal: #{e.message}"
  end

  private

  def require_client!
    return if current_user.client?

    redirect_to root_path, alert: "Billing is only available for client accounts."
  end

  def ensure_stripe_customer!
    return if current_user.stripe_customer_id.present?

    customer = Stripe::Customer.create(email: current_user.email)
    current_user.update!(stripe_customer_id: customer.id)
  end
end
