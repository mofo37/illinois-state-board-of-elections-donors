require 'digest/sha1'

NEXT_LINK_ID = 'ContentPlaceHolder1_gvA1List_phPagerTemplate_gvA1List_PageNext'.freeze

def strip_line_breaks str
  str.delete("\r").delete("\n")
end

namespace :contributions do
  desc 'Scrape donor site'
  task scrape: :environment do
    base_url        = 'https://www.elections.il.gov'
    donors_list_url = base_url + '/CampaignDisclosure/ReportsFiled.aspx'

    puts donors_list_url

    # fetch RSS
    if ENV["USE_RSS_FILE"].present?
      # From a file for faster development feedback loop
      puts '==> Reading RSS file'
      rss_doc = File.open(Rails.root.join 'feed.xml') { |f| Nokogiri::XML(f) }
      puts '==> Read RSS file!'
    else
      puts '==> Fetching root page…'
      root_page     = Nokogiri::HTML(HTTP.follow.get(donors_list_url).to_s)
      puts '==> Fetched root page!'
      rss_link_href = root_page.css('#ContentPlaceHolder1_hypRSSLatestFiledReports').attr('href')
      rss_url       = base_url + rss_link_href

      puts '==> Fetching RSS feed…'
      rss_doc = Nokogiri::XML(HTTP.follow.get(rss_url).to_s)
      puts '==> Fetched RSS feed!'
    end

    # find a1s and b1s
    items = rss_doc.css('item')

    items.each do |item|
      description = item.css('description').text

      type = if description.include?('A-1')
               'A'
             elsif description.include?('B-1')
               'B'
             end

      # skip non-A1s/B1s
      next if type.blank?

      item_pubdate           = item.css('pubDate').text
      item_uid               = item.css('link').text
      existing_contributions = Contribution.where(uid: item_uid).pluck(:id)

      # don't re-fetch contributions that're already saved
      if existing_contributions.present?
        puts "==> Skipping already process RSS item: #{item_pubdate} : #{item_uid}"
        puts "    Existing Contributions: #{existing_contributions.join ' '}"
        puts
        next
      end

      # cleanup url
      item_path = item_uid
      item_path = item_path.sub('\Redirect', '/Redirect')
      item_path = item_path.sub('&amp;', '&')
      item_path = item_path.sub('amp;', '&')

      contributions_to_payee_url = base_url + item_path

      # for pagination
      contribution_browser = Browser.new
      contribution_browser.goto contributions_to_payee_url

      # get contributions, account for website timeout
      inner_attempts = 0
      contributions_to_payee_html = nil

      loop do
        begin
          contributions_to_payee_html = HTTP.follow.get(contributions_to_payee_url).to_s
        rescue Errno::ETIMEDOUT, HTTP::ConnectionError, Net::ReadTimeout
          inner_attempts += 1
          puts "WARNING: 'HTTP.follow.get(contributions_to_payee_url).to_s' timed out #{inner_attempts} times."
          sleep 5 * inner_attempts
        end

        if inner_attempts > 3
          puts "ERROR: 'HTTP.follow.get(contributions_to_payee_url).to_s' timed out 3 times. Exiting…"
          exit 1
        end

        break if contributions_to_payee_html.present?
      end

      # make ready for contribution data extraction
      contribution_doc = Nokogiri::HTML(contributions_to_payee_html)

      # loop through table of contributions, skipping header/footer row
      continue = true
      index = 1

      while continue
        details_table = contribution_doc.css('table#ContentPlaceHolder1_gvA1List')

        if details_table.present?
          puts
          puts '*' * 80
          puts "Starting details page number: #{index}"
          puts '*' * 80
          puts

          rows = if contribution_doc.css("##{NEXT_LINK_ID}").present?
                   details_table.css('tr')[1..-3]
                 else
                   details_table.css('tr')[1..-1]
                 end

          # iterate through rows
          rows.each_with_index do |row, row_index|
            # skip pagination row
            # next if row.attr('class') =~ /SearchListTableHeaderRow/
            break if row.attr('class') =~ /GridViewPagerTemplate/

            # grab data
            payee           = row.css('td')[0].text
            candidate_name  = row.css('td')[5].text
            purpose         = row.css('td')[4].text

            contributed_by  = strip_line_breaks(row.css('td')[0].text.strip)
            contributed_by  = contributed_by.split('Occupation: ').first

            amount_and_date = row.css('td')[2].inner_html.strip
            amount, date    = amount_and_date.split('<br>').map(&:strip)
            amount          = amount.sub('<span>', '')

            month, day, year = date.split('/')
            month            = month.to_s.rjust 2, '0'
            day              = day.to_s.rjust   2, '0'

            filed_at         = Date.parse "#{year}-#{month}-#{day}"

            row_text        = row.css('td').text
            received_by     = strip_line_breaks(row.css('td')[3].css('a').text.strip)

            form            = "#{type}-1"

            # save data
            contribution = Contribution.create!(
              form:           form,
              contributed_by: contributed_by,
              amount:         amount,
              received_by:    received_by,
              contributed_at: filed_at,
              uid:            item_uid,
              year:           year,
              month:          month,
              day:            day
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

        # find if there's are more pages
        pagination_links = contribution_doc.css('a')&.map { |a| a if a.text == 'Next' }
        next_link        = pagination_links.compact.first

        binding.irb

        puts "!!! INFO: ABOUT TO CHECK NAV LINKS"
        if next_link.present?
          puts "!!! INFO: IN NAV LINKS IF"
          # fetch the next page
          contribution_browser.link(id: NEXT_LINK_ID).click
          contribution_doc = Nokogiri::HTML(contribution_browser.html)
          index += 1
        else
          puts "!!! INFO: IN NAV LINKS ELSE"
          # that was the last page, end this loop and move on to next contribution item
          continue = false
          contribution_browser.close
        end

      end # continue
    end # items.each
  end # task
end # namespace
