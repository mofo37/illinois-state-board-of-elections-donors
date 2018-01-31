require "rubyXL"

namespace :spreadsheet do
  desc "Create spreadsheet of today's contributions"
  task create: :environment do
    # set the date for the current spreadsheet lookup
    # reuse that date for filename
    # get contributions from last 24 hours from database
    # save spreadsheet to... somewhere? S3? Who knows.

    contributions = Contribution.all
    a1s = contributions.where(form: "A-1").limit(10)
    b1s = contributions.where(form: "B-1").limit(10)


    # Make a new spreadsheet
    workbook  = RubyXL::Workbook.new
    worksheet = workbook.worksheets[0]
    worksheet.sheet_name = "Contributions"

    total_rows = worksheet.sheet_data.rows.length
    # A-1 headings
    ["Form", "Contributed By", "Amount", "Received By"].each_with_index do |column, index|
      worksheet.add_cell(total_rows, index, column)
    end

    total_rows = worksheet.sheet_data.rows.length

    # A-1 rows
    a1s.group_by(&:received_by).each do |received_by, contributions|
      contributions.each do |contribution|
        [:form, :contributed_by, :amount, :received_by].each_with_index do |column, index|
          worksheet.add_cell(total_rows, index, contribution.send(column)) 
        end

        total_rows += 1
      end
    end
    
    # B-1 headings
    ["Form", "Payee", "Amount", "Payor and Purpose"].each_with_index do |column, index|
      worksheet.add_cell(total_rows, index, column)
    end
    total_rows += 1

    # B-1 rows
    b1s.group_by(&:payor_and_purpose).each do |payor_and_purpose, contributions|
      contributions.each do |contribution|
        [:form, :payee, :amount, :payor_and_purpose].each_with_index do |column, index|
          worksheet.add_cell(total_rows, index, contribution.send(column)) 
        end

        total_rows += 1
      end
    end

    # Save the spreadsheet file
    workbook.write "Report for DATETODO.xlsx"

  end
end
