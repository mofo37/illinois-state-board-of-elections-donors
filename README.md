# TODO 

- fix duplication in spreadsheet
- add pagination
- add bootstrap
- add kill switch to scraper

- send email using AWS
- figure out where to store spreadsheet before send
- schedule daily send from Mary Mayor
- get list of subscribers (26 subscribers)
- add bugsnag

# rake contributions:scrape
# once finished, update day in scratchpad
# select all, copy/paste in console. Run.
# rake contributions:spreadsheet
# change file date in s3 (only for now)
# send Johnny file in email (only for now)


year = 2018
month = 2
day = 21

Contribution.all.each do |c|
  if c.contributed_at.year == year && 
    c.contributed_at.month == month && 
    c.contributed_at.day == day
    c.update delivered_at: nil
  else 
    c.update delivered_at: Time.now
  end
end

a1s = Contribution.where(form: "A-1").where(delivered_at: nil).count
b1s = Contribution.where(form: "B-1").where(delivered_at: nil).count



