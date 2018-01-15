require 'open-uri'

desc "Scrape A1 donor site"
task :scrape_a1_donor_site do
  url = "http://www.elections.il.gov/CampaignDisclosure/ReportsFiled.aspx"
  doc = Nokogiri::HTML(open(url))

  donors_table      = doc.css("table#ctl00_ContentPlaceHolder1_tblLatestReportsFiled")
  donors_table_rows = donors_table.css("tr")
  
  donors_table_rows[1..-1].each do |row|
    report_type = row.css("td")[1].text.strip
    if report_type == "A-1 ($1000+ Year Round)" || report_type == "B-1" #TODO
      puts report_type
    end
  end

end
