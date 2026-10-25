# Tells admins a new sales inquiry came in. Best-effort: the Lead row is
# the source of truth (see /leads), this just makes it timely.
class LeadMailer < ApplicationMailer
  def received(lead, recipient)
    @lead = lead

    mail(to: recipient.email, reply_to: lead.email, subject: "New inquiry from #{lead.name}#{" (#{lead.company})" if lead.company.present?}")
  end
end
