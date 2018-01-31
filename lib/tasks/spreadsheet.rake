require "rubyXL"

namespace :spreadsheet do

  desc "Create spreadsheet of today's contributions"
  task create: :environment do
    # set the date for the current spreadsheet lookup
    # reuse that date for filename

    # set page orientation to landscape
    # set column widths

    # get contributions from last 24 hours from database
    # save spreadsheet to... somewhere? S3? Who knows.

    contributions = Contribution.all
    a1s = contributions.where(form: "A-1").limit(10)
    b1s = contributions.where(form: "B-1").limit(10)


    # Make a new spreadsheet
    workbook  = RubyXL::Workbook.new
    worksheet = workbook.worksheets[0]
    worksheet.sheet_name = "Contributions"

    # Colors
    heading_fill_color       = "000000"
    heading_font_color       = "ffffff"
    group_fill_colors        = ["ffffff", "cccccc"]
    current_group_fill_color = 0

    # Font and row sizes
    font_size  = 12
    row_height = 20


    total_rows = worksheet.sheet_data.rows.length
    # A-1 headings
    ["Form", "Contributed By", "Amount", "Received By"].each_with_index do |column, index|
      worksheet.add_cell(total_rows, index, column)

      # Sets cell text bold
      worksheet.sheet_data[total_rows][index].change_font_bold(true) 

      # Sets cell fill black with white text
      worksheet.sheet_data[total_rows][index].change_fill       heading_fill_color
      worksheet.sheet_data[total_rows][index].change_font_color heading_font_color
    end

    # Sets row height and font size
    worksheet.change_row_height    total_rows, row_height
    worksheet.change_row_font_size total_rows, font_size

    # Sets borders to thin
    worksheet.change_row_border(total_rows, :left, 'thin')
    worksheet.change_row_border(total_rows, :right, 'thin')
    worksheet.change_row_border(total_rows, :bottom, 'thin')
    worksheet.change_row_border(total_rows, :top, 'thin')

    # Sets borders to black
    worksheet.change_row_border_color(total_rows, :left, '000000')
    worksheet.change_row_border_color(total_rows, :right, '000000')
    worksheet.change_row_border_color(total_rows, :bottom, '000000')
    worksheet.change_row_border_color(total_rows, :top, '000000')


    total_rows = worksheet.sheet_data.rows.length


    # A-1 rows
    a1s.group_by(&:received_by).each do |received_by, contributions|
      contributions.each do |contribution|
        [:form, :contributed_by, :amount, :received_by].each_with_index do |column, index|
          worksheet.add_cell(total_rows, index, contribution.send(column)) 

          # Sets cell fill color to grey or white by group
          worksheet.sheet_data[total_rows][index].change_fill group_fill_colors[current_group_fill_color]
        end

        # Sets row height and font size
        worksheet.change_row_height    total_rows, row_height
        worksheet.change_row_font_size total_rows, font_size

        # Sets borders to thin
        worksheet.change_row_border(total_rows, :left, 'thin')
        worksheet.change_row_border(total_rows, :right, 'thin')
        worksheet.change_row_border(total_rows, :bottom, 'thin')
        worksheet.change_row_border(total_rows, :top, 'thin')

        # Sets borders to black
        worksheet.change_row_border_color(total_rows, :left, '000000')
        worksheet.change_row_border_color(total_rows, :right, '000000')
        worksheet.change_row_border_color(total_rows, :bottom, '000000')
        worksheet.change_row_border_color(total_rows, :top, '000000')


        total_rows += 1
      end

      current_group_fill_color = (current_group_fill_color.zero? ? 1 : 0)
    end
    

    # B-1 headings
    ["Form", "Payee", "Amount", "Payor and Purpose"].each_with_index do |column, index|
      worksheet.add_cell(total_rows, index, column)

      # Sets cell text bold
      worksheet.sheet_data[total_rows][index].change_font_bold(true) 

      # Sets cell fill black with white text
      worksheet.sheet_data[total_rows][index].change_fill       heading_fill_color
      worksheet.sheet_data[total_rows][index].change_font_color heading_font_color
    end

    # Sets row height and font size
    worksheet.change_row_height    total_rows, row_height
    worksheet.change_row_font_size total_rows, font_size

    # Sets borders to thin
    worksheet.change_row_border(total_rows, :left, 'thin')
    worksheet.change_row_border(total_rows, :right, 'thin')
    worksheet.change_row_border(total_rows, :bottom, 'thin')
    worksheet.change_row_border(total_rows, :top, 'thin')

    # Sets borders to black
    worksheet.change_row_border_color(total_rows, :left, '000000')
    worksheet.change_row_border_color(total_rows, :right, '000000')
    worksheet.change_row_border_color(total_rows, :bottom, '000000')
    worksheet.change_row_border_color(total_rows, :top, '000000')


    total_rows += 1

    # Reset group fill color to white
    current_group_fill_color = 0


    # B-1 rows
    b1s.group_by(&:payor_and_purpose).each do |payor_and_purpose, contributions|
      contributions.each do |contribution|
        [:form, :payee, :amount, :payor_and_purpose].each_with_index do |column, index|
          worksheet.add_cell(total_rows, index, contribution.send(column)) 

          # Sets cell fill color to grey or white by group
          worksheet.sheet_data[total_rows][index].change_fill group_fill_colors[current_group_fill_color]
        end

        # Sets row height and font size
        worksheet.change_row_height    total_rows, row_height
        worksheet.change_row_font_size total_rows, font_size

        # Sets borders to thin
        worksheet.change_row_border(total_rows, :left, 'thin')
        worksheet.change_row_border(total_rows, :right, 'thin')
        worksheet.change_row_border(total_rows, :bottom, 'thin')
        worksheet.change_row_border(total_rows, :top, 'thin')

        # Sets borders to black
        worksheet.change_row_border_color(total_rows, :left, '000000')
        worksheet.change_row_border_color(total_rows, :right, '000000')
        worksheet.change_row_border_color(total_rows, :bottom, '000000')
        worksheet.change_row_border_color(total_rows, :top, '000000')


        total_rows += 1
      end

      current_group_fill_color = (current_group_fill_color.zero? ? 1 : 0)
    end

    
    # Sets row widths
    {
      0 =>  8,
      1 => 90,
      2 => 15,
      3 => 60
    }.each do |column, size|
      worksheet.change_column_width column, size
    end


    worksheet.sheet_data.rows.each_with_index do |row, index|
      # Sets borders to thin
      worksheet.change_row_border(index, :left, 'thin')
      worksheet.change_row_border(index, :right, 'thin')
      worksheet.change_row_border(index, :bottom, 'thin')
      worksheet.change_row_border(index, :top, 'thin')

      # Sets borders to black
      worksheet.change_row_border_color(index, :left, '000000')
      worksheet.change_row_border_color(index, :right, '000000')
      worksheet.change_row_border_color(index, :bottom, '000000')
      worksheet.change_row_border_color(index, :top, '000000')
    end



    # Save the spreadsheet file
    workbook.write "Report for DATETODO.xlsx"
  end

end
