class TicketMailer < ApplicationMailer
  default from: 'help@thomasinformationtechnology.com'
  
  def new_ticket(ticket)
    @ticket = ticket
    mail(to: 'brett.thomas29.97@gmail.com', subject: "New Help Desk Ticket: #{@ticket.title}")
  end
end

