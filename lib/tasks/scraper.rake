require "digest/sha1"

OUTER_NEXT_LINK_ID = 'ContentPlaceHolder1_gvReportsFiled_phPagerTemplate_gvReportsFiled_PageNext'.freeze
INNER_NEXT_LINK_ID = 'ContentPlaceHolder1_gvA1List_phPagerTemplate_gvA1List_PageNext'.freeze

def strip_line_breaks str
  str.delete("\r").delete("\n")
end

namespace :contributions do
  desc 'Scrape donor site'
  task scrape: :environment do
    base_url        = 'https://www.elections.il.gov/CampaignDisclosure/'
    donors_list_url = base_url + 'ReportsFiled.aspx'

    browser = Browser.new

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
      donors_table = doc.css('table#ContentPlaceHolder1_gvReportsFiled tr')

      donors_table[1..-1].each do |row|
        report_type_td = row.css('td')[1]
        next if report_type_td.nil?

        report_type = report_type_td.text.strip

        next unless ['A-1 ($1000+ Year Round)', 'B-1 ($1000+ Year Round)'].include? report_type

        type = report_type[0] == 'A' ? 'A' : 'B'

        payor = row.css('td')[0].text

        # find the date and time
        filed_at = row.css('td')[3].inner_html.split('<br>').first.sub('<span>', '')

        # extract date/time pieces from filed_at
        month, day, year_plus_time = filed_at.split '/'
        year, time, ampm           = year_plus_time.split
        hour, minute, second       = time.split ':'

        hour = (hour.to_i + 12).to_s if ampm.downcase == 'pm'

        year   = year.rjust   2, '0'
        month  = month.rjust  2, '0'
        day    = day.rjust    2, '0'
        hour   = hour.rjust   2, '0'
        minute = minute.rjust 2, '0'
        second = second.rjust 2, '0'

        # TODO: delete this after confirming date/time pieces work
        Time.zone = "UTC"
        filed_at = Time.zone.strptime(filed_at, '%m/%d/%Y %I:%M:%S %p')

        # find the url
        cats = report_type_td.css('a')
        next if cats.blank?

        details_path = report_type_td.css('a').attr('href')

        details_url = base_url + details_path
        puts details_url

        # fetch the url
        details_browser = Browser.new

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
          details_table = details_doc.css('table#ContentPlaceHolder1_gvA1List')

          if details_table.present?
            # walk through rows
            details_table.css('> tbody > tr')[1..-1].each_with_index do |inner_row, index|
              # skip pagination row
              next if inner_row.attr('class') =~ /GridViewPagerTemplate/

              # grab data
              payee           = inner_row.css('td')[0].text
              candidate_name  = inner_row.css('td')[5].text
              purpose         = inner_row.css('td')[4].text

              contributed_by  = strip_line_breaks(inner_row.css('td')[0].text.strip)
              contributed_by  = contributed_by.split('Occupation: ').first

              amount_and_date = inner_row.css('td')[2].inner_html.strip
              amount          = amount_and_date.split('<br>').map(&:strip).first
              amount          = amount.sub('<span>', '')
              row_text        = inner_row.css('td').text
              uid             = Digest::SHA1.hexdigest(row_text + index.to_s)
              received_by     = strip_line_breaks(inner_row.css('td')[3].css('a').text.strip)

              # save data
              form = "#{type}-1"

              contribution = Contribution.find_or_create_by(
                form:           form,
                contributed_by: contributed_by,
                amount:         amount,
                received_by:    received_by,
                contributed_at: filed_at,
                uid:            uid,
                year:           year,
                month:          month,
                day:            day,
                hour:           hour,
                minute:         minute,
                second:         second
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

              # only scrape recent few days
              next unless contribution.contributed_at < 3.days.ago

              puts 'SUCCESS! Scraped all of the recent contributions.'
              continue       = false
              inner_continue = false
              break
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
            details_browser.link(id: INNER_NEXT_LINK_ID).click
            details_doc = Nokogiri::HTML(details_browser.html)
            inner_index += 1
          elsif inner_next_link.attr('disabled').present?
            inner_continue = false
            details_browser.close
          end

        end # inner_continue

        # ends the scraping
        break unless continue
      end

      # find next link
      pagination_links = doc.css('a')&.map { |a| a if a.text == 'Next' }
      next_link        = pagination_links.compact.first

      # don't click next link if on last page
      if next_link.present?
        browser.link(id: OUTER_NEXT_LINK_ID).click
        doc = Nokogiri::HTML(browser.html)
        index += 1
        # elsif Time.current - contribution.contributed_at < 2
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
