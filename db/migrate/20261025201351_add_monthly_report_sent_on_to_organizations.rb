class AddMonthlyReportSentOnToOrganizations < ActiveRecord::Migration[8.1]
  def change
    add_column :organizations, :monthly_report_sent_on, :date
  end
end
