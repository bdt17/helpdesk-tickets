# Staff log time against a ticket from its page (see TimeEntry).
class TimeEntriesController < ApplicationController
  before_action :authenticate_user!
  before_action :require_staff!
  before_action :set_ticket

  def create
    entry = @ticket.time_entries.build(
      user: current_user,
      minutes: params.dig(:time_entry, :minutes),
      note: params.dig(:time_entry, :note).to_s.strip.presence,
      worked_on: Date.current
    )
    if entry.save
      redirect_to ticket_path(@ticket), notice: "Logged #{TimeEntry.format_minutes(entry.minutes)}."
    else
      redirect_to ticket_path(@ticket), alert: entry.errors.full_messages.to_sentence
    end
  end

  # Your own entries only, unless you're an admin.
  def destroy
    entry = @ticket.time_entries.find(params[:id])
    return redirect_to ticket_path(@ticket), alert: "You can only remove your own time." unless entry.user == current_user || current_user.admin?

    entry.destroy!
    redirect_to ticket_path(@ticket), notice: "Time entry removed."
  end

  private

  def set_ticket
    @ticket = Ticket.find(params[:ticket_id])
  end
end
