namespace :contributions do
  desc "Setup contributions in db for spreadsheet"
  task setup: :environment do
    date = Date.today
    contributions = Contribution.all

    contributions.update_all delivered_at: Time.now
    contributions.on(date).update_all delivered_at: nil

    a1s = contributions.where(form: "A-1").on(date).count
    b1s = contributions.where(form: "B-1").on(date).count
  end
end
