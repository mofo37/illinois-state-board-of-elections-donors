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

    # fetch RSS
    if true && false
      puts '==> Fetching root page…'
      root_page     = Nokogiri::HTML(HTTP.follow.get(donors_list_url).to_s)
      puts '==> Fetched root page!'
      rss_link_href = root_page.css('#ContentPlaceHolder1_hypRSSLatestFiledReports').attr('href')
      rss_url       = base_url + rss_link_href

      puts '==> Fetching RSS feed…'
      rss_doc = Nokogiri::XML(HTTP.follow.get(rss_url).to_s)
      puts '==> Fetched RSS feed!'
    else
      puts '==> Reading RSS file'
      rss_doc = File.open("/Users/s/Desktop/feed.xml") { |f| Nokogiri::XML(f) }
      puts '==> Read RSS file!'
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

      next if type.blank?

      item_uid = item.css('link').text
      existing_contributions = Contribution.where(uid: item_uid).pluck(:id)

      next if existing_contributions.present?

      # cleanup url
      item_path = item_uid
      item_path = item_path.sub('\Redirect', '/Redirect')
      item_path = item_path.sub('&amp;', '&')
      item_path = item_path.sub('amp;', '&')

      contribution_url = base_url + item_path

      # for pagination
      contribution_browser = Browser.new
      contribution_browser.goto contribution_url

      # get contribution
      contribution_doc = Nokogiri::HTML(HTTP.follow.get(contribution_url).to_s)




      continue = true
      index = 1

      while continue
        details_table = contribution_doc.css('table#ContentPlaceHolder1_gvA1List')

        if details_table.present?
          rows = if contribution_doc.css("##{NEXT_LINK_ID}").present?
                   details_table.css('tr')[1..-3]
                 else
                   details_table.css('tr')[1..-1]
                 end

          # walk through rows
          rows.each_with_index do |row, row_index|
            # skip pagination row
            # next if row.attr('class') =~ /header/
            break if row.attr('class') =~ /GridViewPagerTemplate/


            binding.irb if row.css('td')[5].nil?


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
            filed_at         = Date.parse "#{year}-#{month}-#{day}"

            row_text        = row.css('td').text
            received_by     = strip_line_breaks(row.css('td')[3].css('a').text.strip)

            # save data
            form = "#{type}-1"

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

        pagination_links = contribution_doc.css('a')&.map { |a| a if a.text == 'Next' }
        next_link        = pagination_links.compact.first

        puts
        puts '*' * 80
        puts "Details page number: #{index}"
        puts '*' * 80
        puts

        # fetch the url

        if !next_link
          continue = false
          contribution_browser.close
        elsif next_link.present?
          puts "*"*80
          puts "in elsif next_link.attr('disabled').blank?"
          puts "*"*80

          contribution_browser.link(id: NEXT_LINK_ID).click

          contribution_doc = Nokogiri::HTML(contribution_browser.html)
          index += 1
        elsif next_link.attr('disabled').present?
          continue = false
          contribution_browser.close
        end

      end # continue

    end # a1s.each

  end # task
end # namespace
