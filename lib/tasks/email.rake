namespace :go do
  desc 'Email spreadsheet to subscribers'
  task email: :environment do
    # build or get the spreadsheet file
    # save to tmp (or memory?)
    # schedule rake task as daily scheduled job

    # emails = Subscriber.all.pluck(:email)
    emails = ['mofo37@gmail.com', 'veganstraightedge@gmail.com']
    emails.each do |email|
      SubscriberMailer.daily_email(email).deliver_now
    end
  end
end
