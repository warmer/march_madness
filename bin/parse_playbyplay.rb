#!/usr/bin/env ruby

file = ARGV[0]

raise 'Source file name not given' unless file

contents = File.read(file).force_encoding('ASCII-8bit')
lines = contents.split("\n")

exit 0 if lines.count <= 1

header = lines.shift

team_a_score = 0
team_b_score = 0

events = [
  /missed Jumper/,
  /missed Layup/,
  /missed Dunk/,
  /missed Three Point Jumper/,
  /missed Free Throw/,
  /missed Two Point Tip Shot/,

  /made Jumper/,
  /made Layup/,
  /made Dunk/,
  /made Three Point Jumper/,
  /made Free Throw/,
  /made Two Point Tip Shot/,

  /Turnover/,
  /Steal/,
  /Block/,

  /^Foul on/,
  /Technical Foul on/,
  /^Intentional Foul on/,
  /Flagrant/i,
  /Ejected/i,

  /Team Rebound/,
  /Offensive Rebound/,
  /Defensive Rebound/,
  /(Jump Ball|alternating possession)/i,
]

combos = [
  [2, 18],
  [3, 18],
  [4, 18],
  [5, 18],
]

current_state = nil
transitions = (0...(events.size)).to_a.map{|i| Hash.new{|h,k| h[k] = 0} }

lines.each do |line|
  score, team_a_action, team_b_action, time = line.split("\t")
  a_score, b_score = score.split("-").map{|t| t.to_i}
  minutes, seconds = time.split(":").map{|t| t.to_i}

  if team_a_action.empty? and team_b_action.empty?
    raise "Neither team had actions."
  elsif not team_a_action.empty? and not team_b_action.empty?
    raise "Both teams had actions: #{team_a_action}, #{team_b_action}"
  end

  action = team_a_action.empty? ? team_b_action : team_a_action

  state_number = nil
  events.each_with_index do |reg, idx|
    if reg =~ action
      state_number = idx
      break
    end
  end

  raise "No event found for #{action}" unless state_number

  if current_state
    transitions[current_state][state_number] += 1
  end
  current_state = state_number
end

puts transitions
