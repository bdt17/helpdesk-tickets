# #create is the public homepage contact form (no login - these are
# prospects). Everything else is the staff-side list for following up.
class LeadsController < ApplicationController
  before_action :authenticate_user!, except: :create
  before_action :require_staff!, except: :create

  # Public and unauthenticated, so capped per IP like sign-up is.
  rate_limit to: 5, within: 1.hour, only: :create,
             with: -> { redirect_to root_path, alert: "Too many messages sent. Please try again later or email us directly." }

  def index
    @status = params[:status].presence_in(Lead::STATUSES)
    @leads = (@status ? Lead.where(status: @status) : Lead.all).order(created_at: :desc)
    @counts = Lead.group(:status).count
  end

  def create
    # Honeypot: a field hidden from people with CSS that bots fill in.
    # Pretend success so the bot doesn't adapt, but save nothing.
    return redirect_to(root_path, notice: thanks_message) if params[:website].present?

    @lead = Lead.new(lead_params)
    if @lead.save
      User.admin.find_each { |admin| LeadMailer.received(@lead, admin).deliver_later }
      redirect_to root_path, notice: thanks_message
    else
      redirect_to root_path, alert: @lead.errors.full_messages.to_sentence
    end
  end

  def update
    lead = Lead.find(params[:id])
    if lead.update(status: params.dig(:lead, :status))
      redirect_to leads_path(status: params[:return_status]), notice: "#{lead.name} marked #{lead.status}."
    else
      redirect_to leads_path, alert: lead.errors.full_messages.to_sentence
    end
  end

  private

  def lead_params
    params.require(:lead).permit(:name, :email, :company, :phone, :message)
  end

  def thanks_message
    "Thanks! We got your message and will get back to you shortly."
  end
end
