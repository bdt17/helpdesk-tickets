class EscalationAlertJob < ApplicationJob
  queue_as :critical_alerts

  def perform(ticket_id)
    ticket = SopTicket.find(ticket_id)
    
    # CRITICAL tickets > 24h = ESCALATE
    return unless ticket.priority == 'critical' && ticket.created_at < 24.hours.ago

    # TWILIO SMS (FDA/Pharma admin)
    if ENV['TWILIO_SID']
      client = Twilio::REST::Client.new(ENV['TWILIO_SID'], ENV['TWILIO_AUTH_TOKEN'])
      client.messages.create(
        from: ENV['TWILIO_PHONE'],
        to: ENV['ADMIN_PHONE'],
        body: "🚨 FDA CRITICAL: #{ticket.title}\nStatus: #{ticket.status}\n#{root_url}sop_tickets/#{ticket.id}"
      )
    end

    # SLACK WEBHOOK
    if ENV['SLACK_WEBHOOK']
      slack = Slack::Notifier.new(ENV['SLACK_WEBHOOK'])
      slack.ping(
        "🚨 *#{ticket.priority.upcase} FDA TICKET*\n" +
        "🔗 #{ticket.title}\n" +
        "📝 #{ticket.description[0..200]}...\n" +
        "⏰ Created: #{ticket.created_at}\n" +
        "#{root_url}sop_tickets/#{ticket.id}"
      )
    end

    # UPDATE TICKET
    ticket.update(escalated_at: Time.current, status: 'in_progress')
  end
end
