class Browser
  extend Forwardable

  def_delegators :@watir, :goto, :html, :close, :link, :button, :checkbox

  def initialize
    @watir = Watir::Browser.new :chrome, options: WatirOptionsFactory.new.options
  end
end
