# Technician time logged against a ticket (staff only - clients never see
# it). Adds up per client on /reports so the owner can see revenue per
# hour worked, i.e. whether each plan's price actually covers the work.
class TimeEntry < ApplicationRecord
  belongs_to :ticket
  belongs_to :user

  validates :minutes, numericality: { only_integer: true, greater_than: 0, less_than_or_equal_to: 24 * 60 }
  validates :worked_on, presence: true
  validates :note, length: { maximum: 200 }

  # "1h 30m", "45m", "2h"
  def self.format_minutes(total)
    hours, minutes = total.to_i.divmod(60)
    [ (hours.positive? ? "#{hours}h" : nil), (minutes.positive? || hours.zero? ? "#{minutes}m" : nil) ].compact.join(" ")
  end
end
