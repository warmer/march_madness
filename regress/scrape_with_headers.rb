#!/usr/bin/env ruby

text = <<-HERE
  <a href="foo.com">Foo!</a>
  <a href='fizz.buzz'>
    Fizz!
  </a><a href=bizz.bang
  >Bizz</a>
HERE

file = '/tmp/mm_scrape_test.txt'
File.delete(file) if File.exist?(file)
File.write(file, text)

puts `../bin/scrape.rb #{file} "<a\\s+[^>]*href=['\\"]?(?<href>[^'\\"\\s]+)['\\"]?[^>]*>\\s*(?<name>[^<]*?)\\s*<\\/a>" --headers`
