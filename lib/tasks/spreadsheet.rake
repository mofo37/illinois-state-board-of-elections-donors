require "rubyXL"

namespace :spreadsheet do
  desc "Create spreadsheet of today's contributions"
  task create: :environment do
    # get contributions from last 24 hours from database
    # build array of arrays formatted for spreadsheet export
    # save spreadsheet to... somewhere? S3? Who knows.

    contributions = Contribution.all
    a1s = contributions.where(form: "A-1").limit(10)
    b1s = contributions.where(form: "B-1").limit(10)


    # Make a new spreadsheet
    workbook  = RubyXL::Workbook.new
    worksheet = workbook.worksheets[0]
    worksheet.sheet_name = "Contributions"


    # A-1 headings
    ["Form", "Contributed By", "Amount", "Received By"].each_with_index do |column, index|
      worksheet.add_cell(0, index, column)
    end

    total_rows = worksheet.sheet_data.rows.length

    # A-1 rows
    a1s.each do |contribution|
      [:form, :contributed_by, :amount, :received_by].each_with_index do |column, index|
        worksheet.add_cell(total_rows, index, contribution.send(column)) 
      end
      
      total_rows += 1
    end
    

    # B-1 headings
    ["Form", "Payee", "Amount", "Payor and Purpose"].each_with_index do |column, index|
      worksheet.add_cell(total_rows, index, column)
    end
    total_rows += 1

    # B-1 rows
    b1s.each do |contribution|
      [:form, :payee, :amount, :payor_and_purpose].each_with_index do |column, index|
        worksheet.add_cell(total_rows, index, contribution.send(column)) 
      end
      
      total_rows += 1
    end


    # Save the spreadsheet file
    workbook.write "Report for DATETODO.xlsx"



    # serializer = SimpleXlsx::Serializer.new("Report for DATETODO.xlsx") do |doc|
    #   doc.add_sheet("Contributions") do |sheet|
    #     sheet.add_row ["Form", "Contributed By", "Amount", "Received By"]

    #     a1s.each do |contribution|
    #       sheet.add_row [
    #                       contribution.form,
    #                       contribution.contributed_by,
    #                       contribution.amount,
    #                       contribution.received_by
    #                     ]
    #     end

    #   end
    # end



  end
end