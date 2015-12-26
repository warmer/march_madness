#!/usr/bin/env ruby

require_relative '../lib/scraper.rb'

args = ARGV.dup
file = args.shift
regex = args.shift
keep_headers = args.shift

abort "Usage: ./#{File.basename(__FILE__)} input_file regex [--keep_headers]" unless file and regex
abort "#{file} does not exist" unless File.exist?(file)

content = File.read(file).force_encoding('ASCII-8bit')
regex = Regexp.new(regex)

tokens = Scraper.find_tokens(content, regex)
puts tokens[0].keys.sort.join("\t") if keep_headers and tokens.size > 0
tokens.each do |t|
  vals = []
  t.keys.each {|key| vals << t[key]}
  puts vals.join("\t")
end

