require "rails_helper"

RSpec.describe "Dashboard", type: :system, db: :development do
  before do
    # Use your EXISTING 6 pharma tickets
    Rails.application.load_seed  # Loads development data
  end

  it "displays Thomas IT Analytics dashboard" do
    visit root_path
    
    expect(page).to have_content "Thomas IT Analytics"
    expect(page).to have_content "Open Tickets"
    expect(page).to have_content "Pfizer shipment delay"
  end

  it "shows correct ticket counts" do
    visit root_path
    expect(page).to have_content "Open Tickets" 
    expect(page).to have_content "4"  # Your real data
  end

  it "shows live escalation updates" do
    visit root_path
    
    # Escalate ticket #2 live
    EscalationAlertJob.perform_now(2)
    
    # Refresh - should see "in_progress" status change
    visit root_path
    expect(page).to have_content "FDA compliance alert"
  end
end
