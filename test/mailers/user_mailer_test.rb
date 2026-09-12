require "test_helper"

class UserMailerTest < ActionMailer::TestCase
  test "welcome" do
    user = users(:client)
    mail = UserMailer.welcome(user)

    assert_equal "Welcome to Thomas IT Helpdesk", mail.subject
    assert_equal [ user.email ], mail.to
    assert_equal [ "helpdesk@thomasit.com" ], mail.from
    assert_match "File your first ticket", mail.text_part.body.to_s
    assert_match "File your first ticket", mail.html_part.body.to_s
  end
end
