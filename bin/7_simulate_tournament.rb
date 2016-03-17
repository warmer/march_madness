#!/usr/bin/env ruby

require 'yaml'
require_relative 'team_battle.rb'

iterations = (ARGV[0] || '99').to_i

base_dir = File.dirname(File.dirname(File.expand_path(__FILE__)))
tourney_file = File.join(base_dir, 'scraped', 'bracket.tsv')

lines = File.read(tourney_file).split("\n")

round = 1
loop do
  winners = []
  lines.each do |line|
    seed_a, team_a, seed_b, team_b = line.split("\t")
#    if seed_a.to_i == 16
#      winners << "#{seed_b}\t#{team_b}"
#      next
#    end
#    if seed_b.to_i == 16
#      winners << "#{seed_a}\t#{team_a}"
#      next
#    end

    b = TeamBattle.new(team_a, team_b, iterations)
    res = b.run
    res[team_a] += seed_b.to_i - seed_a.to_i
    res[team_b] += seed_a.to_i - seed_b.to_i
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
