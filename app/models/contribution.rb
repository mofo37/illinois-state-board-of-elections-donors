class Contribution < ApplicationRecord
  def payor_and_purpose
    "#{payor} - #{purpose} #{candidate_name}"
  end
end
