require 'forwardable'
require 'watir'

class Browser
  extend Forwardable

  def_delegators :@watir, :goto, :html, :close, :link

  def initialize
    create_directories_if_needed

    options = Selenium::WebDriver::Chrome::Options.new

    # add the option for user-data-dir
    options.add_argument user_data_dir

    # let Selenium know where to look for chrome if we have a hint from
    # heroku. chromedriver-helper & chrome seem to work out of the box on osx,
    # but not on heroku.
    if ENV['GOOGLE_CHROME_BIN'].present?
      chrome_bin = ENV['GOOGLE_CHROME_BIN']
      options.add_argument 'no-sandbox'
      options.binary = chrome_bin
      # give a hint to here too
      Selenium::WebDriver::Chrome.driver_path = '/app/vendor/bundle/bin/chromedriver'
    end

    # headless!
    # keyboard entry wont work until chromedriver 2.31 is released
    options.add_argument 'window-size=1200x600'
    options.add_argument 'headless'
    options.add_argument 'disable-gpu'

    # make the browser
    @watir = Watir::Browser.new :chrome, options: options
  end

  private

  def chrome_dir
    # make a directory for chrome if it doesn't already exist
    File.join Dir.pwd, %w[tmp chrome]
  end

  def user_data_dir
    "--user-data-dir=#{chrome_dir}"
  end

  def create_directories_if_needed
    FileUtils.mkdir_p chrome_dir
  end
end
