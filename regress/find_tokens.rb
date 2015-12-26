#!/usr/bin/env ruby

require_relative '../lib/scraper.rb'

puts Scraper.find_tokens('this is a foo', /(?:\b|\s)(?<word>\w+)(?:\b|\s)/)

text = <<-HERE
  <a href="foo.com">Foo!</a>
  <a href='fizz.buzz'>
    Fizz!
  </a><a href=bizz.bang
  >Bizz</a>
HERE
puts Scraper.find_anchors(text)

