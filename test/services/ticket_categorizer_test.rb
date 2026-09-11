require "test_helper"

class TicketCategorizerTest < ActiveSupport::TestCase
  setup do
    @ticket = tickets(:one)
    @original_key = ENV["ANTHROPIC_API_KEY"]
  end

  teardown do
    ENV["ANTHROPIC_API_KEY"] = @original_key
  end

  test "returns nil when no API key is configured" do
    ENV["ANTHROPIC_API_KEY"] = nil
    assert_nil TicketCategorizer.call(@ticket)
  end

  test "returns the category Claude suggests" do
    ENV["ANTHROPIC_API_KEY"] = "test-key"

    with_stubbed_claude_response("network") do
      assert_equal "network", TicketCategorizer.call(@ticket)
    end
  end

  test "rejects a category outside Ticket::CATEGORIES" do
    ENV["ANTHROPIC_API_KEY"] = "test-key"

    with_stubbed_claude_response("not-a-real-category") do
      assert_nil TicketCategorizer.call(@ticket)
    end
  end

  test "returns nil (not an exception) when the request errors" do
    ENV["ANTHROPIC_API_KEY"] = "test-key"

    Net::HTTP.stub(:start, ->(*) { raise Timeout::Error }) do
      assert_nil TicketCategorizer.call(@ticket)
    end
  end

  private

  # Net::HTTP.start's block form is awkward to stub directly: Minitest's
  # Object#stub always returns val_or_callable regardless of what the block
  # returns, and calls the block with `block_args` rather than a real
  # connection object. So `response` (val_or_callable) is what
  # TicketCategorizer#request_category actually sees as the method's
  # result, and `fake_http` just needs to survive `http.request(request)`
  # being called on it inside that block.
  def with_stubbed_claude_response(category_text, &block)
    response = Net::HTTPOK.new("1.1", "200", "OK")
    body = { content: [ { type: "text", text: category_text } ] }.to_json
    response.define_singleton_method(:body) { body }

    fake_http = Object.new
    fake_http.define_singleton_method(:request) { |_request| response }

    Net::HTTP.stub(:start, response, fake_http, &block)
  end
end
