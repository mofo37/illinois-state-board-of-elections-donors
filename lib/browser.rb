require 'forwardable'
require 'watir'
require_relative 'watir_options_factory'

class Browser
  extend Forwardable

  def_delegators :@watir, :goto, :html, :close, :link

  def initialize
    create_directories_if_needed
    @watir = Watir::Browser.new :chrome, options: WatirOptionsFactory.new.options
  end

  private

  def create_directories_if_needed
    FileUtils.mkdir_p chrome_dir
  end

  # TODO: DRY this up from WatirOptionsFactory#chrome_dir
  def chrome_dir
    # make a directory for chrome if it doesn't already exist
    File.join Dir.pwd, %w[tmp chrome]
  end
end
