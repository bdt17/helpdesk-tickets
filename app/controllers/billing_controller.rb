# Client-facing subscription management. Actual subscription state is only
# ever written by Webhooks::StripeController — this controller only ever
# *asks* Stripe to start a checkout or open the billing portal; it never
# marks an organization as subscribed itself, so a client can't grant
# themselves a paid plan by hitting these actions directly.
#
# Billing lives on Organization, not the individual User (Phase 12): a
# client with no organization yet is simply someone who hasn't subscribed
# — one gets created for them, with them as its owner, on their first
# checkout. Only the owner can change the plan or open the billing
# portal; other seats on the same organization can see the current plan
# but not touch it.
class BillingController < ApplicationController
  before_action :authenticate_user!
  before_action :require_client!

  def show
    @plans = Plan::ALL
    @organization = current_user.organization
  end

  def checkout
    plan = Plan.find(params[:plan])
    annual = params[:interval] == "year"
    price_id = plan && (annual ? Plan.annual_price_id_for(plan.key) : Plan.price_id_for(plan.key))
    return redirect_to billing_path, alert: "Unknown plan." unless price_id.present?
    return redirect_to billing_path, alert: "Only the account owner can change plans." unless current_user.organization.nil? || current_user.org_owner?

    ensure_organization_and_stripe_customer!

    session = Stripe::Checkout::Session.create(
      customer: current_user.organization.stripe_customer_id,
      client_reference_id: current_user.id.to_s,
      mode: "subscription",
      line_items: [ { price: price_id, quantity: 1 } ],
      # Lets a client enter a coupon created in the Stripe dashboard -
      # e.g. a launch discount for early clients - without a code change.
      allow_promotion_codes: true,
      **trial_options,
      success_url: billing_success_url,
      cancel_url: billing_url
    )

    redirect_to session.url, allow_other_host: true
  rescue Stripe::StripeError => e
    # Stripe's own message can include account/request details meant for
    # us, not the client - log it, show something generic.
    Rails.logger.error "Stripe error (start checkout): #{e.class} #{e.message}"
    redirect_to billing_path, alert: "Couldn't start checkout. Please try again or contact support."
  end

  def success
    flash[:notice] = if params[:purchase] == "extra_tickets"
      "Thanks! Your extra tickets will be ready in a few seconds - refresh if they don't show yet."
    else
      "Thanks! Your subscription is being set up — this can take a few seconds to confirm."
    end
    redirect_to billing_path
  end

  # One-time purchase of extra tickets. Like #checkout, this only starts a
  # Stripe Checkout - credits are added by the webhook once Stripe confirms
  # payment, never here.
  def extra_tickets
    return redirect_to billing_path, alert: "Extra tickets aren't available right now." unless Plan.extra_tickets_enabled?
    return redirect_to billing_path, alert: "Only the account owner can buy extra tickets." unless current_user.organization.nil? || current_user.org_owner?

    quantity = params[:quantity].to_i.clamp(1, Plan::MAX_EXTRA_TICKETS_PER_PURCHASE)
    ensure_organization_and_stripe_customer!
    organization = current_user.organization

    session = Stripe::Checkout::Session.create(
      customer: organization.stripe_customer_id,
      client_reference_id: current_user.id.to_s,
      mode: "payment",
      line_items: [ {
        price_data: {
          currency: "usd",
          unit_amount: Plan.extra_ticket_price_cents,
          product_data: { name: "Extra support ticket" }
        },
        quantity: quantity
      } ],
      metadata: { kind: "extra_tickets", organization_id: organization.id.to_s, quantity: quantity.to_s },
      allow_promotion_codes: true,
      success_url: billing_success_url(purchase: "extra_tickets"),
      cancel_url: billing_url
    )

    redirect_to session.url, allow_other_host: true
  rescue Stripe::StripeError => e
    Rails.logger.error "Stripe error (extra tickets): #{e.class} #{e.message}"
    redirect_to billing_path, alert: "Couldn't start checkout. Please try again or contact support."
  end

  def portal
    return redirect_to billing_path, alert: "No billing account on file yet." if current_user.organization&.stripe_customer_id.blank?
    return redirect_to billing_path, alert: "Only the account owner can manage billing." unless current_user.org_owner?

    session = Stripe::BillingPortal::Session.create(
      customer: current_user.organization.stripe_customer_id,
      return_url: billing_url
    )

    redirect_to session.url, allow_other_host: true
  rescue Stripe::StripeError => e
    # Stripe's own message can include account/request details meant for
    # us, not the client - log it, show something generic.
    Rails.logger.error "Stripe error (open billing portal): #{e.class} #{e.message}"
    redirect_to billing_path, alert: "Couldn't open billing portal. Please try again or contact support."
  end

  private

  # STRIPE_TRIAL_DAYS (unset = no trial) adds a free trial to every new
  # subscription. Organization#subscribed? already treats "trialing" as
  # subscribed, so trial users get the full plan immediately.
  def trial_options
    days = ENV["STRIPE_TRIAL_DAYS"].to_i
    days.positive? ? { subscription_data: { trial_period_days: days } } : {}
  end

  def require_client!
    return if current_user.client?

    redirect_to root_path, alert: "Billing is only available for client accounts."
  end

  def ensure_organization_and_stripe_customer!
    if current_user.organization.nil?
      organization = Organization.create!(name: "#{current_user.email}'s Account")
      current_user.update!(organization: organization, org_role: "owner")
    end

    return if current_user.organization.stripe_customer_id.present?

    customer = Stripe::Customer.create(email: current_user.email)
    current_user.organization.update!(stripe_customer_id: customer.id)
  end
end
