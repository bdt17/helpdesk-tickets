class AddTestDataToSopTickets < ActiveRecord::Migration[8.1]
  def up
    SopTicket.create!([
      { title: "FDA audit violation Pfizer site-42", description: "21 CFR 11 violation detected", priority_level: "critical", ticket_status: "open" },
      { title: "Merck shipment delay", description: "Temperature excursion reported", priority_level: "high", ticket_status: "in_progress" },
      { title: "Routine IT maintenance", description: "Server patching required", priority_level: "low", ticket_status: "open" }
    ])
  end

  def down
    SopTicket.delete_all
  end
end
