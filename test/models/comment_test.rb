require "test_helper"

class CommentTest < ActiveSupport::TestCase
  test "requires a body" do
    comment = Comment.new(ticket: tickets(:one), user: users(:employee))
    refute comment.valid?
    assert_includes comment.errors[:body], "can't be blank"
  end

  test "belongs to a ticket and a user" do
    comment = Comment.create!(ticket: tickets(:one), user: users(:employee), body: "Any update?")
    assert_equal tickets(:one), comment.ticket
    assert_equal users(:employee), comment.user
  end

  test "internal defaults to false" do
    comment = Comment.create!(ticket: tickets(:one), user: users(:employee), body: "Any update?")
    refute comment.internal?
  end
end
