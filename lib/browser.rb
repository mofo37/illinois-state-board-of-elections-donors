require 'watir'

class Browser
  def initialize
    options = Selenium::WebDriver::Chrome::Options.new

    # make a directory for chrome if it doesn't already exist
    chrome_dir = File.join Dir.pwd, %w[tmp chrome]
    FileUtils.mkdir_p chrome_dir
    user_data_dir = "--user-data-dir=#{chrome_dir}"
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

  def goto url
    @watir.goto url
  end

  def html
    @watir.html
  end

  def close
    @watir.close
  end

  def link options
    @watir.link options
  end
end
