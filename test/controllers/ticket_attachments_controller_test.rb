require "test_helper"

class TicketAttachmentsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @ticket = tickets(:one) # owned by users(:employee)
    @ticket.attachments.attach(io: file_fixture("test_image.png").open, filename: "test_image.png", content_type: "image/png")
    @attachment = @ticket.reload.attachments.first
  end

  test "requires authentication" do
    get ticket_attachment_url(@ticket, @attachment)
    assert_redirected_to new_user_session_url
  end

  test "the ticket's owner can fetch their own attachment" do
    sign_in users(:employee)
    get ticket_attachment_url(@ticket, @attachment)
    assert_response :success
    assert_equal "image/png", response.media_type
    assert_equal file_fixture("test_image.png").binread, response.body
    assert_match(/\Ainline/, response.headers["Content-Disposition"])
  end

  test "non-image attachments download rather than render inline" do
    @ticket.attachments.attach(io: file_fixture("test_note.txt").open, filename: "note.txt", content_type: "text/plain")
    note = @ticket.reload.attachments.find_by!(blob: ActiveStorage::Blob.find_by!(filename: "note.txt"))

    sign_in users(:employee)
    get ticket_attachment_url(@ticket, note)
    assert_response :success
    assert_match(/\Aattachment/, response.headers["Content-Disposition"])
  end

  test "never hands out a reusable, unauthenticated Active Storage URL" do
    sign_in users(:employee)
    get ticket_attachment_url(@ticket, @attachment)
    assert_no_match %r{/rails/active_storage/}, response.headers["Location"].to_s
  end

  test "staff can fetch a client's attachment" do
    sign_in users(:agent)
    get ticket_attachment_url(@ticket, @attachment)
    assert_response :success
  end

  test "another employee cannot fetch someone else's attachment" do
    sign_in users(:other_employee)
    get ticket_attachment_url(@ticket, @attachment)
    assert_redirected_to root_url
  end

  test "404s for an attachment id that belongs to a different ticket" do
    other_ticket = tickets(:two)
    other_ticket.attachments.attach(io: file_fixture("test_note.txt").open, filename: "note.txt", content_type: "text/plain")
    other_attachment = other_ticket.reload.attachments.first

    sign_in users(:employee)
    get ticket_attachment_url(@ticket, other_attachment)
    assert_response :not_found
  end
end
