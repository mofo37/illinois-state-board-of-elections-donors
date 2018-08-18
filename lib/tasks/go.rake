namespace :contributions do
  desc "Run all rake tasks to generate today's spreadsheet"
  task go: [:scrape, :setup, :spreadsheet] do
  end
end
