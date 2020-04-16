namespace :contributions do
  desc 'Setup contributions in db for spreadsheet'
  task :setup, [:year, :month, :day] => :environment do |t, args|
    puts
    puts '-' * 80
    puts

    if args[:year].present? && args[:month].present? && args[:day].present?
      # Use rake task command line args:
      # rake contributions:setup[2018, 12, 31]
      year  = args[:year].to_s.rjust  2, '0'
      month = args[:month].to_s.rjust 2, '0'
      day   = args[:day].to_s.rjust   2, '0'
    else
      # Use rake task command line args:
      Time.zone = 'America/Chicago'
      year      = Time.zone.today.year
      month     = Time.zone.today.month
      day       = Time.zone.today.day

      the_day        = Time.parse "#{year}-#{month}-#{day}"
      the_day_before = the_day - 1.day

      year  = the_day_before.year.to_s.rjust  2, '0'
      month = the_day_before.month.to_s.rjust 2, '0'
      day   = the_day_before.day.to_s.rjust   2, '0'
    end

    year  = year.to_s.rjust  2, '0'
    month = month.to_s.rjust 2, '0'
    day   = day.to_s.rjust   2, '0'

    puts "Year:  #{year}"
    puts "Month: #{month}"
    puts "Day:   #{day}"
    puts

    contributions = Contribution.where(year: year, month: month, day: day)

    puts 'Updating Contribution.delivered_at to now for: all '
    Contribution.update_all delivered_at: Time.current

    puts "Updating Contribution.delivered_at to nil for: #{year}-#{month}-#{day}"
    contributions.update_all delivered_at: nil
    puts

    a1s = contributions.where form: 'A-1'
    b1s = contributions.where form: 'B-1'

    puts "A1s: #{a1s.count.to_s.rjust 5, ' '}"
    puts "B1s: #{b1s.count.to_s.rjust 5, ' '}"

    puts
    puts '-' * 80
    puts
  end
end
