require 'forwardable'
require 'watir'

class Browser
  extend Forwardable

  def_delegators :@watir, :goto, :html, :close, :link

  def initialize
    create_directories_if_needed
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

  def options
    selenium_options = Selenium::WebDriver::Chrome::Options.new

    # add the option for user-data-dir
    selenium_options.add_argument user_data_dir

    # headless!
    # keyboard entry wont work until chromedriver 2.31 is released
    selenium_options.add_argument 'window-size=1200x600'
    selenium_options.add_argument 'headless'
    selenium_options.add_argument 'disable-gpu'

    # TODO: this isn't used or working yet 2019-02-18
    # setup_heroku

    selenium_options
  end

  def chrome_bin
    ENV['GOOGLE_CHROME_BIN']
  end

  def on_heroku?
    chrome_bin.present?
  end

  def setup_heroku
    if on_heroku?
      # TODO: this isn't used or working yet 2019-02-18
      # let Selenium know where to look for chrome if we have a hint from
      # heroku. chromedriver-helper & chrome seem to work out of the box on macOS,
      # but not on heroku.
      options.add_argument 'no-sandbox'
      options.binary = chrome_bin
      # give a hint to here too
      Selenium::WebDriver::Chrome.driver_path = '/app/vendor/bundle/bin/chromedriver'
    end
  end
end
