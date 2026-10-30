# A few starter help-center articles, created as DRAFTS so the owner can
# review the wording before anything goes public (publish from /help).
# Uses its own minimal model so later changes to Article can't break it,
# and skips any slug that already exists.
class AddStarterHelpArticles < ActiveRecord::Migration[8.1]
  class StarterArticle < ActiveRecord::Base
    self.table_name = "articles"
  end

  ARTICLES = [
    {
      slug: "how-to-open-a-good-ticket", category: "Getting started",
      title: "How to open a ticket that gets fixed fast",
      summary: "What to include in a support ticket so a technician can start on it right away.",
      body: <<~TEXT
        The more a technician knows up front, the less back-and-forth before your problem is fixed.

        ## Include these details
        - What you were trying to do
        - What happened instead, including the exact wording of any error message
        - When it started, and whether anything changed around then (an update, a new device, a move)
        - Who is affected: just you, a few people, or everyone
        - A screenshot, if you can take one

        ## Pick the right priority
        - Critical: the business can't work (everyone is offline, a key system is down)
        - High: you can't do your job, and there's no workaround
        - Medium: something is broken, but you can work around it for now
        - Low: questions, small annoyances and requests that can wait

        You'll get updates on the ticket as it's worked on. Reply on the ticket itself so the whole history stays in one place.
      TEXT
    },
    {
      slug: "try-this-before-opening-a-ticket", category: "Getting started",
      title: "Five things to try before opening a ticket",
      summary: "Quick checks that fix a lot of everyday computer problems.",
      body: <<~TEXT
        These take a couple of minutes and fix a surprising number of problems. If they don't, open a ticket and mention what you already tried.

        - Restart the computer (a real restart, not just closing the lid)
        - Check the cables and power: is everything plugged in and switched on?
        - Close and reopen the program that's misbehaving
        - Check whether a coworker has the same problem - if so, it's probably not your computer
        - Install pending updates, then restart again

        If you see an error message, take a screenshot before you restart so you can attach it to the ticket.
      TEXT
    },
    {
      slug: "slow-or-dropping-wi-fi", category: "Network & Wi-Fi Support",
      title: "Slow or dropping Wi-Fi: what to check first",
      summary: "Simple steps to narrow down a slow or unreliable Wi-Fi connection.",
      body: <<~TEXT
        Wi-Fi problems usually come from distance, interference or one misbehaving device. These steps help narrow it down.

        ## Quick checks
        - Move closer to the wireless access point or router and test again
        - Turn Wi-Fi off and on again on your device, or forget the network and reconnect
        - Check whether wired computers are slow too - if so, the problem is likely the internet connection, not the Wi-Fi
        - Restart your device

        ## When to open a ticket
        If several people are affected, the connection drops repeatedly, or it's slow everywhere in the office, open a ticket. Include where in the building you are, roughly when it happens, and whether it affects everyone. Please don't restart shared network equipment yourself unless a technician asks you to.
      TEXT
    },
    {
      slug: "spotting-phishing-emails", category: "Accounts, Access & Security",
      title: "How to spot a phishing email",
      summary: "Warning signs of a fake email, and what to do if you clicked something.",
      body: <<~TEXT
        Phishing emails pretend to be from someone you trust to get you to click a link, open an attachment or hand over a password.

        ## Warning signs
        - Urgency or threats: "your account will be closed today"
        - A sender address that doesn't quite match the company it claims to be
        - Links whose real address (hover over them to see it) doesn't match the company
        - Unexpected attachments, invoices or shared files
        - Requests for passwords, gift cards or changes to payment details

        ## If you're not sure
        Don't click. Contact the sender another way, such as a phone number you already have, or forward it to us in a ticket.

        ## If you already clicked or entered a password
        Open a Critical ticket right away. Changing the password quickly and checking the account limits the damage, so don't wait.
      TEXT
    },
    {
      slug: "new-employee-it-checklist", category: "Accounts, Access & Security",
      title: "Starting or leaving: the IT checklist",
      summary: "What to tell us when someone joins or leaves, so accounts are ready on day one and closed on the last day.",
      body: <<~TEXT
        Give us a few days' notice when someone joins or leaves, so accounts and equipment are ready in time.

        ## When someone joins
        - Their name, start date and role
        - Which email, shared folders and software they need
        - Whether they need a computer, phone or other equipment
        - Whose access theirs should match, if anyone's

        ## When someone leaves
        - Their last day, and whether access should end at a specific time
        - Who should receive their email and files
        - Any equipment to collect

        Open a ticket with these details. For departures, Medium priority with the date in the title works well.
      TEXT
    }
  ].freeze

  def up
    ARTICLES.each do |attrs|
      next if StarterArticle.exists?(slug: attrs[:slug])

      StarterArticle.create!(attrs.merge(published: false))
    end
  end

  def down
    StarterArticle.where(slug: ARTICLES.map { |a| a[:slug] }, published: false).delete_all
  end
end
