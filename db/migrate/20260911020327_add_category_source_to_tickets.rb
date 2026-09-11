# Lets /api/ai/status report something true instead of a hardcoded
# "tickets_processed: Ticket.count" that had nothing to do with AI. Every
# ticket defaults to "manual"; TicketCategorizationJob flips it to "ai"
# only when Claude actually supplied the category.
class AddCategorySourceToTickets < ActiveRecord::Migration[8.1]
  def change
    add_column :tickets, :category_source, :string, default: "manual", null: false
  end
end
