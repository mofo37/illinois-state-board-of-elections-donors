namespace :spreadsheet do
  desc "Create spreadsheet of today's contributions'"
  task create: :environment do
    # get contributions from last 24 hours from database
    # build array of arrays formatted for spreadsheet export
    # save spreadsheet to... somewhere? S3? Who knows.

    contributions = Contribution.all
    require 'simple_xlsx'

serializer = SimpleXlsx::Serializer.new("test.xlsx") do |doc|
  doc.add_sheet("People") do |sheet|
    sheet.add_row(%w{DoB Name Occupation})
    sheet.add_row([Date.parse("July 31, 1912"), 
                  "Milton Friedman", 
                  "Economist / Statistician"])
  end
end



  end
end