require 'forwardable'
require 'watir'
require_relative 'watir_options_factory'

class Browser
  extend Forwardable

  def_delegators :@watir, :goto, :html, :close, :link

  def initialize
    @watir = Watir::Browser.new :chrome, options: WatirOptionsFactory.new.options
  end
end
