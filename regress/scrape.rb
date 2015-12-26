#!/usr/bin/env ruby

file = File.expand_path(File.join(__FILE__, '../mm_scrape_test.txt'))
regex = '<a\\s+[^>]*href=[\'\\"]?(?<href>[^\'\\"\\s]+)[\'\\"]?[^>]*>\\s*(?<name>[^<]*?)\\s*<\\/a>'
bin = File.expand_path(File.join(__FILE__, '../../bin/scrape.rb'))
puts `#{bin} #{file} "#{regex}"`
