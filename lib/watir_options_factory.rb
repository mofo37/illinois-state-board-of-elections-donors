class WatirOptionsFactory
  attr_reader :options

  def initialize
    @options = Selenium::WebDriver::Chrome::Options.new

    # add the option for user-data-dir
    @options.add_argument user_data_dir

    # headless!
    # keyboard entry wont work until chromedriver 2.31 is released
    @options.add_argument 'window-size=1200x600'
    @options.add_argument 'headless'
    @options.add_argument 'disable-gpu'

    # TODO: this isn't used or working yet 2019-02-18
    # setup_heroku
  end

  private

  # TODO: DRY this up from Browser#chrome_dir
  def chrome_dir
    # make a directory for chrome if it doesn't already exist
    File.join Dir.pwd, %w[tmp chrome]
  end

  def user_data_dir
    "--user-data-dir=#{chrome_dir}"
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
      @options.add_argument 'no-sandbox'
      @options.binary = chrome_bin
      # give a hint to here too
      Selenium::WebDriver::Chrome.driver_path = '/app/vendor/bundle/bin/chromedriver'
    end
  end
end