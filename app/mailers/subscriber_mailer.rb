class SubscriberMailer < ApplicationMailer
  default from: ENV["DEFAULT_FROM_EMAIL"]

  def daily_email(email)
    date = Time.now.strftime("%m-%d-%Y")
    spreadsheet_file = "Report for #{date}.xlsx"
    spreadsheet_file_path = "tmp/#{spreadsheet_file.gsub(" ", "\ ")}"

    mail to: email, subject: "A1 and B1 Report for #{date}", attachments[spreadsheet_file] = File.read(spreadsheet_file_path)
  end
end
