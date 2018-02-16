require "rubyXL"
require 'aws-sdk'


namespace :contributions do

  desc "Create spreadsheet of today's contributions"
  task spreadsheet: :environment do
    # set the date for the current spreadsheet lookup
    # reuse that date for filename

    # get contributions from last 24 hours from database
    # save spreadsheet to... somewhere? S3? Who knows.

    contributions = Contribution.all
    a1s = contributions.where(form: "A-1").where(delivered_at: nil)
    b1s = contributions.where(form: "B-1").where(delivered_at: nil)


    # Make a new spreadsheet
    workbook  = RubyXL::Workbook.new
    worksheet = workbook.worksheets[0]
    worksheet.sheet_name = "Contributions"

    # Colors
    heading_fill_color       = "000000"
    heading_font_color       = "ffffff"
    group_fill_colors        = ["ffffff", "cccccc"]
    current_group_fill_color = 0
    border_color             = "000000"

    # Sizes: font, row and border 
    font_size   = 12
    row_height  = 20
    border_size = "thin"

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

    total_rows = worksheet.sheet_data.rows.length


    # A-1 rows
    a1s.group_by(&:received_by).each do |received_by, contributions|
      contributions.each do |contribution|
        [:form, :contributed_by, :amount, :received_by].each_with_index do |column, index|
          worksheet.add_cell(total_rows, index, contribution.send(column)) 

          # Sets cell fill color to grey or white by group
          worksheet.sheet_data[total_rows][index].change_fill group_fill_colors[current_group_fill_color]
        end

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
      # Sets row height and font size
      worksheet.change_row_height    index, row_height
      worksheet.change_row_font_size index, font_size

      # Sets borders to thin and black
      %w(top right bottom left).each do |side|
        worksheet.change_row_border       index, side, border_size
        worksheet.change_row_border_color index, side, border_color
      end
    end

    date = Time.now.strftime("%m-%d-%Y")
    file_name = "Report-for-#{date}.xlsx"
    file = workbook.write "#{Rails.root}/tmp/#{file_name}"

    Aws.config.update({
      region: 'us-east-1',
      credentials: Aws::Credentials.new(ENV["AWS_ACCESS_KEY_ID"], ENV["AWS_SECRET_ACCESS_KEY"])
    })

    # client is for making file public. s3 is for file upload.
    client = Aws::S3::Client.new
    s3 = Aws::S3::Resource.new

    # reference an existing bucket by name
    bucket_name = ENV["S3_BUCKET"]
    bucket = s3.bucket(bucket_name)
    bucket_url = bucket.url

    # Sets a bucket to public-read
    client.put_bucket_acl({
      acl: "public-read",
      bucket: bucket_name,
    })

    # Get just the file name
    name = File.basename(file)

    # Create the object to upload
    obj = s3.bucket(bucket_name).object(name)

    # Upload it      
    obj.upload_file(file)

    # Setting the object to public-read
    client.put_object_acl({
      acl: "public-read",
      bucket: bucket_name,
      key: file_name,
    })

    download_url = [bucket_url, file_name].join("/")

    a1s.update_all(delivered_at: Time.now)
    b1s.update_all(delivered_at: Time.now)
  end

end
