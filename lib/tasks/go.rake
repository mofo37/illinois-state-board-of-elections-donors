desc "Run all rake tasks to generate today’s spreadsheet"
task go: ['go:scrape', 'go:setup', 'go:spreadsheet'] do
end
