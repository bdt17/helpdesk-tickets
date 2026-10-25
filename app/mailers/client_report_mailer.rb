class ClientReportMailer < ApplicationMailer
  def monthly(organization, recipient, stats)
    @organization = organization
    @stats = stats.symbolize_keys

    subject = if @stats[:resolved].positive?
      "#{@stats[:month_name]}: we resolved #{@stats[:resolved]} #{"issue".pluralize(@stats[:resolved])} for #{organization.name}"
    else
      "#{@stats[:month_name]}: your Thomas IT support summary"
    end
    mail(to: recipient.email, subject: subject)
  end
end
