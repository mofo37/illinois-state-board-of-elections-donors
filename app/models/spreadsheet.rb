class Spreadsheet < ApplicationRecord
  validates :url, uniqueness: true
end
