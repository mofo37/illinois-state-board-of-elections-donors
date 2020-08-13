class Contribution < ApplicationRecord
  # validates :uid, uniqueness: true

  scope :on, lambda { |date|
               where(
                 'contributed_at BETWEEN ? AND ?',
                 (Time.zone.parse("#{date.year}-#{date.month}-#{date.day} 17:00:00 z") - 1.day),
                 Time.zone.parse("#{date.year}-#{date.month}-#{date.day} 17:00:00 z")
               )
  }

  default_scope { order(contributed_at: :desc) }

  def payor_and_purpose
    "#{payor} - #{purpose} #{candidate_name}"
  end
end
