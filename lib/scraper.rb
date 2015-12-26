require_relative 'http.rb'

module Scraper
  # returns an array of maps containing the tokens matching the given regex
  def self.find_tokens(page, regex)
    res = []
    page.scan(regex) { res << $~ }
    res.map! do |r|
      h = {}
      r.names.each {|name| h[name] = r[name] }
      h
    end
    res
  end

  # Returns an array of hashes containing the href/name components of all
  # anchors on the page
  def self.find_anchors(page)
    r = /<a\s+[^>]*href=['"]?(?<href>[^'"\s]+)['"]?[^>]*>\s*(?<name>[^<]*?)\s*<\/a>/i
    find_tokens(page, r)
  end
end
