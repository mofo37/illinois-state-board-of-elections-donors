require "open-uri"
require "watir"

def strip_line_breaks(str)
  str.gsub("\r", "").gsub("\n", "")
end

namespace :contributions do

  desc "Scrape donor site"
  task scrape: :environment do
    base_url        = "http://www.elections.il.gov/CampaignDisclosure/"
    donors_list_url = base_url + "ReportsFiled.aspx"

    browser = Watir::Browser.new
    browser.goto donors_list_url

    doc = Nokogiri::HTML(browser.html)
    continue = true
    index = 1

    while continue do
      donors_table = doc.css("table#ctl00_ContentPlaceHolder1_tblLatestReportsFiled tr")

      donors_table[1..-1].each do |row|
        report_type_td = row.css("td")[1]
        report_type    = report_type_td.text.strip

        
        if report_type == "A-1 ($1000+ Year Round)" || report_type == "B-1 ($1000+ Year Round)"
          type = report_type[0] == "A" ? "A" : "B"

          payor = row.css("td")[0].text

          # find the date and time
          filed_at = row.css("td")[3].inner_html.split("<br>").first.sub("<span>", "")
          filed_at = DateTime.strptime(filed_at, "%m/%d/%Y %I:%M:%S %p")

          # find the url
          details_path = report_type_td.css("a").attr("href")
          details_url  = base_url + details_path 


          # fetch the url
          details_browser = Watir::Browser.new
          details_browser.goto details_url

          details_doc = Nokogiri::HTML(details_browser.html)
          inner_continue = true 
          inner_index = 1

          while inner_continue do

            # find the table on the new page
            # table_id = "table#ct100_ContentPlaceHolder1_tbl#{type}1List"
            # puts table_id
            # details_table = details_doc.css(table_id)
            # puts details_table
            details_table = details_doc.css("table").last

            unless details_table.blank?
              # walk through rows
              
              details_table.css("tr")[1..-1].each do |row|
                # grab data
                payee            = row.css("td")[0].text
                candidate_name   = row.css("td")[5].text
                purpose          = row.css("td")[4].text

                contributed_by   = strip_line_breaks(row.css("td")[0].text.strip)

                amount_and_date  = row.css("td")[2].inner_html.strip
                amount           = amount_and_date.split("<br>").map{|x| x.strip}.first
                amount           = amount.sub("<span>", "")

                received_by      = strip_line_breaks(row.css("td")[3].css("a").text.strip)
                uid              = row.css("th").first.attr("id")

                # save data
                contribution                   = Contribution.new
                contribution.form              = "#{type}-1"

                if type == "B"
                  contribution.payor             = payor
                  contribution.candidate_name    = candidate_name
                  contribution.purpose           = purpose
                  contribution.payee             = payee
                end

                contribution.contributed_by    = contributed_by
                contribution.amount            = amount
                contribution.received_by       = received_by
                contribution.contributed_at    = filed_at
                contribution.uid               = uid
                contribution.save

                puts contribution.inspect
                puts
              end
            end

            inner_next_link = details_doc.css("a")&.map{|a| a if a.text == "Next"}.compact.first

            puts
            puts "*"*80
            puts inner_index
            puts "*"*80
            puts

            if !inner_next_link
              inner_continue = false
              details_browser.close
            elsif inner_next_link.attr("disabled").blank?
              details_browser.link(id: "ctl00_ContentPlaceHolder1_Listnavigation_btnPageNext").click
              details_doc = Nokogiri::HTML(details_browser.html)
              inner_index += 1
            elsif inner_next_link.attr("disabled").present?
              inner_continue = false
            end 

          end # inner_continue
        end # if report type
          
          # "#ctl00_ContentPlaceHolder1_ListNavigation_btnPageNext"

      end # donors_table.each
    
      # find next link
      next_link = doc.css("a")&.map{|a| a if a.text == "Next"}.compact.first
      
      puts
      puts "*"*80
      puts index
      puts "*"*80
      puts

      # don't click next link if on last page
      if next_link.attr("disabled").blank?
        browser.link(id: "ctl00_ContentPlaceHolder1_ListNavigation_btnPageNext").click
        doc = Nokogiri::HTML(browser.html)
        index += 1
      else
        # exit when there is no next link
        continue = false
      end
    end # while
      
  end # task
end # namespace
