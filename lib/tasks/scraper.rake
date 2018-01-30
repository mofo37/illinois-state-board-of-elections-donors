require "open-uri"

def strip_line_breaks(str)
  str.gsub("\r", "").gsub("\n", "")
end

desc "Scrape A1 donor site"
task :scrape_a1_donor_site => :environment do
  base_url        = "http://www.elections.il.gov/CampaignDisclosure/"
  donors_list_url = base_url + "ReportsFiled.aspx"
  doc             = Nokogiri::HTML(open(donors_list_url))

  donors_table = doc.css("table#ctl00_ContentPlaceHolder1_tblLatestReportsFiled tr")
  
  donors_table[1..-1].each do |row|
    report_type_td = row.css("td")[1]
    report_type    = report_type_td.text.strip
    
    if report_type == "A-1 ($1000+ Year Round)" || report_type == "B-1 ($1000+ Year Round)"

      # find the date and time
      filed_at = row.css("td")[3].inner_html.split("<br>").first.sub("<span>", "")
      filed_at = DateTime.strptime(filed_at, '%m/%d/%Y %I:%M:%S %p')

      # find the url
      details_path = report_type_td.css("a").attr("href")
      details_url  = base_url + details_path 

      # find payor for B-1's 
      payor = row.css("td")[0].text

      # fetch the url
      details_doc = Nokogiri::HTML(open(details_url))

      # find the table on the new page
      details_table = details_doc.css("table#ctl00_ContentPlaceHolder1_tblA1List")

      unless details_table.blank?
        # walk through rows
        
        details_table.css("tr")[1..-1].each do |row|
          # grab data
          contributed_by   = strip_line_breaks(row.css("td")[0].text.strip)

          amount_and_date  = row.css("td")[2].inner_html.strip
          amount           = amount_and_date.split("<br>").map{|x| x.strip}.first
          amount           = amount.sub("<span>", "")

          received_by      = strip_line_breaks(row.css("td")[3].css("a").text.strip)

          uid              = row.css("th").first.attr("id")
          
          # save data
          # TODO add contributed at to db so no dupes
          contribution                = Contribution.new
          contribution.form           = "A-1"
          contribution.contributed_by = contributed_by
          contribution.amount         = amount
          contribution.received_by    = received_by
          contribution.contributed_at = filed_at
          contribution.uid            = uid
          contribution.save

          puts contribution.inspect
          puts
        end
      end
    end
  end
end
