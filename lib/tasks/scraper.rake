require 'digest/sha1'

OUTER_NEXT_LINK_ID = 'ContentPlaceHolder1_gvReportsFiled_phPagerTemplate_gvReportsFiled_PageNext'.freeze
INNER_NEXT_LINK_ID = 'ContentPlaceHolder1_gvA1List_phPagerTemplate_gvA1List_PageNext'.freeze

def strip_line_breaks str
  str.delete("\r").delete("\n")
end

namespace :contributions do
  desc 'Scrape donor site'
  task scrape: :environment do
    base_url        = 'https://www.elections.il.gov'
    donors_list_url = base_url + '/CampaignDisclosure/ReportsFiled.aspx'

    # fetch RSS
    if false
      puts '==> Fetching root page…'
      root_page     = Nokogiri::HTML(open(donors_list_url))
      puts '==> Fetched root page!'
      rss_link_href = root_page.css('#ContentPlaceHolder1_hypRSSLatestFiledReports').attr('href')
      rss_url       = base_url + rss_link_href

      puts '==> Fetching RSS feed…'
      rss_doc = Nokogiri::XML(open(rss_url))
      puts '==> Fetched RSS feed!'
    else
      puts '==> Reading RSS file'
      rss_doc = File.open("/Users/s/Desktop/feed.xml") { |f| Nokogiri::XML(f) }
      puts '==> Read RSS file!'
    end

    # find a1s and b1s
    items = rss_doc.css('item')

    a1s = items.map do |item|
      item if item.css('description').text.include?('A-1')
    end.compact

    b1s = items.map do |item|
      item if item.css('description').text.include?('B-1')
    end.compact

    a1s.each do |item|
      item_uid = item.css('link').text
      existing_contributions = Contribution.where(uid: item_uid).pluck(:id)

      next if existing_contributions.present?

      # cleanup url
      item_path = item_uid
      item_path = item_path.sub('\Redirect', '/Redirect')
      item_path = item_path.sub('&amp;', '&')
      item_path = item_path.sub('amp;', '&')

      contribution_url = base_url + item_path

      # get contribution
      contribution_doc = Nokogiri::HTML(open(contribution_url))




      type = 'A'
      inner_continue = true
      inner_index = 1

      while inner_continue
        details_table = contribution_doc.css('table#ContentPlaceHolder1_gvA1List')

        # binding.irb

        if details_table.present?
          # walk through rows
          details_table.css('> tr')[1..-1].each_with_index do |inner_row, inner_row_index|
            # skip pagination row
            next if inner_row.attr('class') =~ /GridViewPagerTemplate/

            # grab data
            payee           = inner_row.css('td')[0].text
            candidate_name  = inner_row.css('td')[5].text
            purpose         = inner_row.css('td')[4].text

            contributed_by  = strip_line_breaks(inner_row.css('td')[0].text.strip)
            contributed_by  = contributed_by.split('Occupation: ').first

            amount_and_date = inner_row.css('td')[2].inner_html.strip
            amount, date    = amount_and_date.split('<br>').map(&:strip)
            amount          = amount.sub('<span>', '')

            month, day, year = date.split('/')
            filed_at         = Date.parse "#{year}-#{month}-#{day}"

            row_text        = inner_row.css('td').text
            received_by     = strip_line_breaks(inner_row.css('td')[3].css('a').text.strip)

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

        inner_pagination_links = contribution_doc.css('a')&.map { |a| a if a.text == 'Next' }
        inner_next_link        = inner_pagination_links.compact.first

        puts
        puts '*' * 80
        puts "Details page number: #{inner_index}"
        puts '*' * 80
        puts


        # TEMP: Don't loop on the same Contribution page
        inner_continue = false

        # TODO: Handle pagination on Contribution page
        # if !inner_next_link
        #   inner_continue = false
        # elsif inner_next_link.attr('disabled').blank?
        #   # details_browser.link(id: INNER_NEXT_LINK_ID).click
        #   # contribution_doc = Nokogiri::HTML(details_browser.html)
        #   inner_index += 1
        # elsif inner_next_link.attr('disabled').present?
        #   inner_continue = false
        # end

      end # inner_continue






    end # a1s.each

  end # task
end # namespace
