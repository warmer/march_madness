#!/usr/bin/env ruby

require 'yaml'
require_relative 'team_battle.rb'

base_dir = File.dirname(File.dirname(File.expand_path(__FILE__)))
tourney_file = File.join(base_dir, 'scraped', 'bracket.tsv')

lines = File.read(tourney_file).split("\n")

round = 1
loop do
  winners = []
  lines.each do |line|
    seed_a, team_a, seed_b, team_b = line.split("\t")
    b = TeamBattle.new(team_a, team_b, 99)
    res = b.run
    if res[team_a] > res[team_b]
      winners << "#{seed_a}\t#{team_a}"
    else
      winners << "#{seed_b}\t#{team_b}"
    end
  end
  if lines.count == 1
    puts "WINNER: #{winners}"
    break
  end
  lines = []
  line = nil
  winners.each do |winner|
    if line
      lines << [line, winner].join("\t")
      line = nil
    else
      line = winner
    end
  end
  puts "==== Round #{round} winners ===="
  puts winners
  round += 1
end
puts lines.count
