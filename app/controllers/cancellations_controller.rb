# The in-app "cancel my plan" flow, instead of sending clients straight
# to Stripe's portal: asks why (recorded here and on the Stripe
# subscription), offers a one-time discount when a retention coupon is
# configured, and cancels at the end of the paid period rather than
# immediately - so the client keeps what they paid for and can still
# change their mind. Staff get an email either way.
#
# Like BillingController, these only ask Stripe to change the
# subscription; subscription_status itself still comes from the webhook.
# cancel_at is also written here so the page reflects the change right
# away - the webhook that follows sets the same value.
class CancellationsController < ApplicationController
  before_action :authenticate_user!
  before_action :require_subscribed_owner!

  def new
    redirect_to billing_path, notice: "Your plan is already set to end on #{ends_on}." if @organization.canceling?
  end

  def create
    reason = params[:reason].presence_in(Organization::CANCELLATION_REASONS.keys)
    return redirect_to billing_cancel_path, alert: "Please pick a reason." unless reason

    comment = params[:comment].to_s.strip.first(2000).presence
    subscription = Stripe::Subscription.update(
      @organization.stripe_subscription_id,
      cancel_at_period_end: true,
      cancellation_details: { feedback: reason, comment: comment }.compact
    )
    @organization.update!(
      cancel_at: subscription.cancel_at && Time.zone.at(subscription.cancel_at),
      cancellation_reason: reason,
      cancellation_comment: comment
    )
    notify_staff(:canceled)

    redirect_to billing_path, notice: "Your plan is canceled and will end on #{ends_on}. Support continues as normal until then."
  rescue Stripe::StripeError => e
    stripe_failed(e, "cancel")
  end

  # One use per organization: the conditional UPDATE claims the offer
  # before Stripe is called, so a double-click can't apply it twice.
  def accept_offer
    claimed = Plan.retention_coupon_id.present? &&
      Organization.where(id: @organization.id, retention_offer_used_at: nil).update_all(retention_offer_used_at: Time.current) == 1
    return redirect_to billing_path, alert: "That offer isn't available." unless claimed

    begin
      Stripe::Subscription.update(@organization.stripe_subscription_id, discounts: [ { coupon: Plan.retention_coupon_id } ])
    rescue Stripe::StripeError
      @organization.update_column(:retention_offer_used_at, nil) # give the offer back
      raise
    end
    notify_staff(:kept_with_discount)

    redirect_to billing_path, notice: "Thanks for staying! #{Plan::RETENTION_OFFER.capitalize} has been applied."
  rescue Stripe::StripeError => e
    stripe_failed(e, "apply retention offer")
  end

  def resume
    return redirect_to billing_path unless @organization.canceling?

    Stripe::Subscription.update(@organization.stripe_subscription_id, cancel_at_period_end: false)
    @organization.update!(cancel_at: nil)
    notify_staff(:resumed)

    redirect_to billing_path, notice: "Welcome back - your plan will keep renewing as normal."
  rescue Stripe::StripeError => e
    stripe_failed(e, "resume")
  end

  private

  def require_subscribed_owner!
    @organization = current_user.organization
    return if current_user.client? && current_user.org_owner? && @organization&.subscribed? && @organization.stripe_subscription_id.present?

    redirect_to billing_path, alert: "Only the account owner of an active plan can do that."
  end

  def ends_on
    @organization.cancel_at&.strftime("%B %-d, %Y") || "the end of your billing period"
  end

  def notify_staff(outcome)
    User.admin.find_each do |admin|
      BillingMailer.cancellation_staff_alert(@organization, admin, outcome.to_s).deliver_later
    end
  end

  def stripe_failed(error, action)
    Rails.logger.error "Stripe error (#{action}): #{error.class} #{error.message}"
    redirect_to billing_path, alert: "Something went wrong. Please try again or contact support."
  end
end
