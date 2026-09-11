# Calls the Claude API to suggest one of Ticket::CATEGORIES for a new
# ticket. This is the real feature behind what used to be a fully faked
# `/api/ai/status` endpoint (hardcoded "model": "gpt-4o-mini", not wired to
# anything). Requires ANTHROPIC_API_KEY; with no key set, #call returns nil
# and callers (TicketCategorizationJob) just leave the ticket manually
# categorized, the same way Stripe features no-op without their keys.
class TicketCategorizer
  ENDPOINT = "https://api.anthropic.com/v1/messages"
  MODEL = "claude-haiku-4-5-20251001"
  ANTHROPIC_VERSION = "2023-06-01"

  def self.configured?
    ENV["ANTHROPIC_API_KEY"].present?
  end

  def self.call(ticket)
    new(ticket).call
  end

  def initialize(ticket)
    @ticket = ticket
  end

  def call
    return nil unless self.class.configured?

    category = request_category
    Ticket::CATEGORIES.include?(category) ? category : nil
  rescue StandardError => e
    Rails.logger.warn "TicketCategorizer failed for ticket ##{@ticket.id}: #{e.class} #{e.message}"
    nil
  end

  private

  def request_category
    uri = URI(ENDPOINT)
    request = Net::HTTP::Post.new(uri)
    request["x-api-key"] = ENV["ANTHROPIC_API_KEY"]
    request["anthropic-version"] = ANTHROPIC_VERSION
    request["content-type"] = "application/json"
    request.body = {
      model: MODEL,
      max_tokens: 8,
      system: "Classify the support ticket into exactly one of these categories: " \
              "#{Ticket::CATEGORIES.join(', ')}. Respond with only the category word, nothing else.",
      messages: [ { role: "user", content: "Title: #{@ticket.title}\nDescription: #{@ticket.description}" } ]
    }.to_json

    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true, open_timeout: 5, read_timeout: 10) do |http|
      http.request(request)
    end
    return nil unless response.is_a?(Net::HTTPSuccess)

    JSON.parse(response.body).dig("content", 0, "text").to_s.strip.downcase
  end
end
