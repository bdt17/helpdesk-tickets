# Runs on the 1st (config/recurring.yml): emails each paying
# organization's owner a summary of last month. monthly_report_sent_on is
# what keeps a retried or re-run job from emailing anyone twice.
class MonthlyClientReportJob < ApplicationJob
  queue_as :default

  def perform(month = 1.month.ago.to_date)
    month = month.to_date.beginning_of_month

    Organization.where(subscription_status: %w[active trialing past_due]).find_each do |organization|
      next if organization.monthly_report_sent_on.present? && organization.monthly_report_sent_on >= month
      next unless (owner = organization.owner)

      stats = MonthlyClientReport.new(organization, month).stats
      ClientReportMailer.monthly(organization, owner, stats).deliver_later
      organization.update_columns(monthly_report_sent_on: month)
    end
  end
end
