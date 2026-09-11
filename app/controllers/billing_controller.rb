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
    return redirect_to billing_path, alert: "Unknown plan." unless plan && Plan.price_id_for(plan.key).present?
    return redirect_to billing_path, alert: "Only the account owner can change plans." unless current_user.organization.nil? || current_user.org_owner?

    ensure_organization_and_stripe_customer!

    session = Stripe::Checkout::Session.create(
      customer: current_user.organization.stripe_customer_id,
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
    return redirect_to billing_path, alert: "No billing account on file yet." if current_user.organization&.stripe_customer_id.blank?
    return redirect_to billing_path, alert: "Only the account owner can manage billing." unless current_user.org_owner?

    session = Stripe::BillingPortal::Session.create(
      customer: current_user.organization.stripe_customer_id,
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
