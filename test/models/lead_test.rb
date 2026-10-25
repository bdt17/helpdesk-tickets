require "test_helper"

class LeadTest < ActiveSupport::TestCase
  test "requires a name and a valid email" do
    assert_not Lead.new(email: "a@b.co").valid?
    assert_not Lead.new(name: "A", email: "not-an-email").valid?
    assert Lead.new(name: "A", email: "a@b.co").valid?
  end

  test "normalizes email and defaults to new" do
    lead = Lead.create!(name: "A", email: "  Pat@Example.COM ")
    assert_equal "pat@example.com", lead.email
    assert_equal "new", lead.status
  end

  test "rejects unknown statuses" do
    assert_not Lead.new(name: "A", email: "a@b.co", status: "bogus").valid?
  end
end
