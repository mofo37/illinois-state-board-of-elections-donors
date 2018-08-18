require 'open-uri'
require 'watir'

def strip_line_breaks(str)
  str.delete("\r").delete("\n")
end

def new_browser
  options = Selenium::WebDriver::Chrome::Options.new

  # make a directory for chrome if it doesn't already exist
  chrome_dir = File.join Dir.pwd, %w[tmp chrome]
  FileUtils.mkdir_p chrome_dir
  user_data_dir = "--user-data-dir=#{chrome_dir}"
  # add the option for user-data-dir
  options.add_argument user_data_dir

  # let Selenium know where to look for chrome if we have a hint from
  # heroku. chromedriver-helper & chrome seem to work out of the box on osx,
  # but not on heroku.
  if chrome_bin = ENV['GOOGLE_CHROME_BIN']
    options.add_argument 'no-sandbox'
    options.binary = chrome_bin
    # give a hint to here too
    Selenium::WebDriver::Chrome.driver_path = '/app/vendor/bundle/bin/chromedriver'
  end

  # headless!
  # keyboard entry wont work until chromedriver 2.31 is released
  options.add_argument 'window-size=1200x600'
  options.add_argument 'headless'
  options.add_argument 'disable-gpu'

  # make the browser
  Watir::Browser.new :chrome, options: options
end

namespace :contributions do
  desc 'Scrape donor site'
  task scrape: :environment do
    base_url        = 'https://www.elections.il.gov/CampaignDisclosure/'
    donors_list_url = base_url + 'ReportsFiled.aspx'

    browser = new_browser

    attempts = 0
    loop do
      begin
        browser.goto donors_list_url
      rescue Net::ReadTimeout
        attempts += 1
        puts "WARNING: 'browser.goto donors_list_url' timed out #{attempts} times."
        sleep 5 * attempts
      end

      if attempts > 3
        puts "ERROR: 'browser.goto donors_list_url' timed out 3 times. Exiting…"
        exit 1
      end

      break if browser.html.present?
    end

    doc = Nokogiri::HTML(browser.html)
    continue = true
    index = 1

    while continue
      donors_table = doc.css('table#ctl00_ContentPlaceHolder1_tblLatestReportsFiled tr')

      donors_table[1..-1].each do |row|
        report_type_td = row.css('td')[1]
        report_type    = report_type_td.text.strip

        next unless ['A-1 ($1000+ Year Round)', 'B-1 ($1000+ Year Round)'].include? report_type

        type = report_type[0] == 'A' ? 'A' : 'B'

        payor = row.css('td')[0].text

        # find the date and time
        filed_at = row.css('td')[3].inner_html.split('<br>').first.sub('<span>', '')
        filed_at = Time.strptime(filed_at, '%m/%d/%Y %I:%M:%S %p')

        # find the url
        cats = report_type_td.css('a')
        next if cats.blank?
        details_path = report_type_td.css('a').attr('href')

        details_url  = base_url + details_path
        puts details_url.inspect

        # fetch the url
        details_browser = new_browser

        inner_attempts = 0
        loop do
          begin
            details_browser.goto details_url
          rescue Net::ReadTimeout
            inner_attempts += 1
            puts "WARNING: 'details_browser.goto details_url' timed out #{inner_attempts} times."
            sleep 5 * inner_attempts
          end

          if inner_attempts > 3
            puts "ERROR: 'details_browser.goto details_url' timed out 3 times. Exiting…"
            exit 1
          end

          break if details_browser.html.present?
        end

        details_doc = Nokogiri::HTML(details_browser.html)
        inner_continue = true
        inner_index = 1

        while inner_continue
          details_table = details_doc.css('table').last

          if details_table.present?
            # walk through rows
            details_table.css('tr')[1..-1].each do |inner_row|
              # grab data
              payee           = inner_row.css('td')[0].text
              candidate_name  = inner_row.css('td')[5].text
              purpose         = inner_row.css('td')[4].text

              contributed_by  = strip_line_breaks(row.css('td')[0].text.strip)
              contributed_by  = contributed_by.split('Occupation: ').first

              amount_and_date = inner_row.css('td')[2].inner_html.strip
              amount          = amount_and_date.split('<br>').map(&:strip).first
              amount          = amount.sub('<span>', '')

              received_by     = strip_line_breaks(row.css('td')[3].css('a').text.strip)
              uid             = inner_row.css('th').first.attr('id')

              # save data
              form = "#{type}-1"

              contribution = Contribution.find_or_create_by(
                form:           form,
                contributed_by: contributed_by,
                amount:         amount,
                received_by:    received_by,
                contributed_at: filed_at,
                uid:            uid
              )

              if type == 'B'
                contribution.payor          = payor
                contribution.candidate_name = candidate_name
                contribution.purpose        = purpose
                contribution.payee          = payee
              end

              contribution.save
              puts contribution.inspect
              puts
            end
          end

          inner_pagination_links = details_doc.css('a')&.map { |a| a if a.text == 'Next' }
          inner_next_link        = inner_pagination_links.compact.first

          puts
          puts '*' * 80
          puts "Details page number: #{inner_index}"
          puts '*' * 80
          puts

          if !inner_next_link
            inner_continue = false
            details_browser.close
          elsif inner_next_link.attr('disabled').blank?
            details_browser.link(id: 'ctl00_ContentPlaceHolder1_Listnavigation_btnPageNext').click
            details_doc = Nokogiri::HTML(details_browser.html)
            inner_index += 1
          elsif inner_next_link.attr('disabled').present?
            inner_continue = false
            details_browser.close
          end

        end # inner_continue
        # if report type

        # "#ctl00_ContentPlaceHolder1_ListNavigation_btnPageNext"

        # donors_table.each
      end
      # find next link
      pagination_links = doc.css('a')&.map { |a| a if a.text == 'Next' }
      next_link        = pagination_links.compact.first

      # don't click next link if on last page
      if next_link.attr('disabled').blank?
        browser.link(id: 'ctl00_ContentPlaceHolder1_ListNavigation_btnPageNext').click
        doc = Nokogiri::HTML(browser.html)
        index += 1
        # elsif Time.now - contribution.contributed_at < 2
        #   continue = false
        #   browser.close
      else
        # exit when there is no next link
        continue = false
        browser.close
      end
    end # while

    puts
    puts
  end # task
end # namespace
