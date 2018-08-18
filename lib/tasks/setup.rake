namespace :contributions do
  desc "Setup contributions in db for spreadsheet"
  task setup: :environment do
    # if Date.yesterday does not work because of timezones:
    # date = Date.today.advance(:days => -1)
    date = Date.today
    contributions = Contribution.all

    puts "Updating all 'delivered_at' to now"
    contributions.update_all delivered_at: Time.now
    puts "Updating today's 'delivered_at' to nil"
    contributions.on(date).update_all delivered_at: nil

    a1s = contributions.where(form: "A-1").on(date).count
    b1s = contributions.where(form: "B-1").on(date).count
    puts "A1s: #{a1s}"
    puts "B1s: #{b1s}"

    puts 
    puts
  end
end
