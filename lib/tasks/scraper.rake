require "open-uri"
require "watir"

def strip_line_breaks(str)  
  str.gsub("\r", "").gsub("\n", "")
end

def new_browser
  options = Selenium::WebDriver::Chrome::Options.new

  # make a directory for chrome if it doesn't already exist
  chrome_dir = File.join Dir.pwd, %w(tmp chrome)
  FileUtils.mkdir_p chrome_dir
  user_data_dir = "--user-data-dir=#{chrome_dir}"
  # add the option for user-data-dir
  options.add_argument user_data_dir

  # let Selenium know where to look for chrome if we have a hint from
  # heroku. chromedriver-helper & chrome seem to work out of the box on osx,
  # but not on heroku.
  if chrome_bin = ENV["GOOGLE_CHROME_BIN"]
    options.add_argument "no-sandbox"
    options.binary = chrome_bin
    # give a hint to here too
    Selenium::WebDriver::Chrome.driver_path = "/app/vendor/bundle/bin/chromedriver"
  end

  # headless!
  # keyboard entry wont work until chromedriver 2.31 is released
  options.add_argument "window-size=1200x600"
  options.add_argument "headless"
  options.add_argument "disable-gpu"

  # make the browser
  Watir::Browser.new :chrome, options: options
end

namespace :contributions do
  desc "Scrape donor site"
  task scrape: :environment do
    puts "in scrape"
    # base_url        = "http://www.elections.il.gov/CampaignDisclosure/"
    # donors_list_url = base_url + "ReportsFiled.aspx"

    # browser = new_browser

    # attempts = 0
    # loop do
    #   begin
    #     browser.goto donors_list_url
    #   rescue Net::ReadTimeout
    #     attempts += 1
    #     puts "WARNING: 'browser.goto donors_list_url' timed out #{ attempts } times."
    #     sleep 5 * attempts
    #   end

    #   if attempts > 3
    #     puts "ERROR: 'browser.goto donors_list_url' timed out 3 times. Exiting…"
    #     exit 1
    #   end

    #   break if browser.html.present?
    # end

    # doc = Nokogiri::HTML(browser.html)
    # continue = true
    # index = 1

    # while continue do
    #   donors_table = doc.css("table#ctl00_ContentPlaceHolder1_tblLatestReportsFiled tr")

    #   donors_table[1..-1].each do |row|
    #     report_type_td = row.css("td")[1]
    #     report_type    = report_type_td.text.strip

        
    #     if report_type == "A-1 ($1000+ Year Round)" ||
    #        report_type == "B-1 ($1000+ Year Round)"
    #       type = report_type[0] == "A" ? "A" : "B"

    #       payor = row.css("td")[0].text

    #       # find the date and time
    #       filed_at = row.css("td")[3].inner_html.split("<br>").first.sub("<span>", "")
    #       filed_at = DateTime.strptime(filed_at, "%m/%d/%Y %I:%M:%S %p")

    #       # find the url
    #       details_path = report_type_td.css("a").attr("href")
    #       details_url  = base_url + details_path 

    #       # fetch the url
    #       details_browser = new_browser

    #       inner_attempts = 0
    #       loop do
    #         begin
    #           details_browser.goto details_url
    #         rescue Net::ReadTimeout
    #           inner_attempts += 1
    #           puts "WARNING: 'details_browser.goto details_url' timed out #{ inner_attempts } times."
    #           sleep 5 * inner_attempts
    #         end

    #         if inner_attempts > 3
    #           puts "ERROR: 'details_browser.goto details_url' timed out 3 times. Exiting…"
    #           exit 1
    #         end

    #         break if details_browser.html.present?
    #       end

    #       details_doc = Nokogiri::HTML(details_browser.html)
    #       inner_continue = true 
    #       inner_index = 1

    #       while inner_continue do

    #         # find the table on the new page
    #         # table_id = "table#ct100_ContentPlaceHolder1_tbl#{ type }1List"
    #         # puts table_id
    #         # details_table = details_doc.css(table_id)
    #         # puts details_table
    #         details_table = details_doc.css("table").last

    #         unless details_table.blank?
    #           # walk through rows
              
    #           details_table.css("tr")[1..-1].each do |row|
    #             # grab data
    #             payee           = row.css("td")[0].text
    #             candidate_name  = row.css("td")[5].text
    #             purpose         = row.css("td")[4].text

    #             contributed_by  = strip_line_breaks(row.css("td")[0].text.strip)
    #             contributed_by  = contributed_by.split("Occupation: ").first

    #             amount_and_date = row.css("td")[2].inner_html.strip
    #             amount          = amount_and_date.split("<br>").map{ |x| x.strip }.first
    #             amount          = amount.sub("<span>", "")

    #             received_by     = strip_line_breaks(row.css("td")[3].css("a").text.strip)
    #             uid             = row.css("th").first.attr("id")

    #             # save data
    #             form = "#{ type }-1"

    #             contribution = Contribution.find_or_create_by({
    #               form:           form,
    #               contributed_by: contributed_by,
    #               amount:         amount,
    #               received_by:    received_by,
    #               contributed_at: filed_at,
    #               uid:            uid,
    #             })

    #             if type == "B"
    #               contribution.payor          = payor
    #               contribution.candidate_name = candidate_name
    #               contribution.purpose        = purpose
    #               contribution.payee          = payee
    #             end

    #             contribution.save
    #             puts contribution.inspect
    #             puts
    #           end
    #         end

    #         inner_next_link = details_doc.css("a")&.map{ |a| a if a.text == "Next" }.compact.first

    #         puts
    #         puts "*"*80
    #         puts "Details page number: #{ inner_index }"
    #         puts "*"*80
    #         puts

    #         if !inner_next_link
    #           inner_continue = false
    #           details_browser.close
    #         elsif inner_next_link.attr("disabled").blank?
    #           details_browser.link(id: "ctl00_ContentPlaceHolder1_Listnavigation_btnPageNext").click
    #           details_doc = Nokogiri::HTML(details_browser.html)
    #           inner_index += 1
    #         elsif inner_next_link.attr("disabled").present?
    #           inner_continue = false
    #           details_browser.close
    #         end 

    #       end # inner_continue
    #     end # if report type
          
    #       # "#ctl00_ContentPlaceHolder1_ListNavigation_btnPageNext"

    #   end # donors_table.each
    
    #   # find next link
    #   next_link = doc.css("a")&.map{ |a| a if a.text == "Next" }.compact.first

    #   # don't click next link if on last page
    #   if next_link.attr("disabled").blank?
    #     browser.link(id: "ctl00_ContentPlaceHolder1_ListNavigation_btnPageNext").click
    #     doc = Nokogiri::HTML(browser.html)
    #     index += 1
    #   else
    #     # exit when there is no next link
    #     continue = false
    #     browser.close
    #   end
    # end # while
      
  end # task
end # namespace
