#!/usr/bin/env ruby

args = ARGV.dup
file = args.shift
regex = args.shift
keep_headers = args.shift

abort "Usage: ./#{File.basename(__FILE__)} input_file regex [--keep_headers]" unless file and regex
abort "#{file} does not exist" unless File.exist?(file)

content = File.read(file).force_encoding('ASCII-8bit')
regex = Regexp.new(regex)

res = []
content.scan(regex) { res << $~ }
tokens = res.map {|r| h = {}; r.names.each {|name| h[name] = r[name] }; h}

puts tokens[0].keys.sort.join("\t") if keep_headers and tokens.size > 0
tokens.each {|t| puts t.keys.sort.map {|key| t[key]}.join("\t") }
