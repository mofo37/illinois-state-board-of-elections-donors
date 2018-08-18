# TODO 

- fix duplication in spreadsheet
- add pagination
- add bootstrap
- add kill switch to scraper

- fix headless Chrome on Heroku
  https://github.com/jormon/minimal-chrome-on-heroku
  https://github.com/edelpero/watir-examples/blob/master/watir_on_heroku.md
  https://github.com/watir/watir/issues/555
  

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

```ruby
year = 2018
month = 2
day = 21

Contribution.all.each do |c|
  if c.contributed_at.year == year && 
    c.contributed_at.month == month && 
    c.contributed_at.day == day
    c.update delivered_at: nil
  else 
    c.update delivered_at: Time.current
  end
end

a1s = Contribution.where(form: "A-1").where(delivered_at: nil).count
b1s = Contribution.where(form: "B-1").where(delivered_at: nil).count
```
