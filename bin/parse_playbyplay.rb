#!/usr/bin/env ruby

file = ARGV[0]
raise 'Source file name not given' unless file

lines = File.read(file).force_encoding('ASCII-8bit').split("\n")
exit 0 if lines.count <= 1

header = lines.shift

events = {
  missed_jumper: {
    regex: /missed (Jumper|Two Point Tip Shot)/,
    posession: true},
  missed_layup: {regex: /missed Layup/, posession: true},
  missed_dunk: {regex: /missed Dunk/, posession: true},
  missed_3pt: {regex: /missed Three Point Jumper/, posession: true},
  missed_ft: {regex: /missed Free Throw/, posession: true},

  made_jumper: {regex: /made (Jumper|Two Point Tip Shot)/,
    posession: true, points: 2},
  made_layup: {regex: /made Layup/, posession: true, points: 2},
  made_dunk: {regex: /made Dunk/, posession: true, points: 2},
  made_3pt: {regex: /made Three Point Jumper/, posession: true,
    points: 3},
  made_ft: {regex: /made Free Throw/, posession: true, points: 1},

  turnover: {regex: /Turnover/, posession: true},
  steal: {regex: /Steal/, posession: true, follows: :turnover},
  block: {regex: /Block/, posession: false},

  foul: {regex: /Foul on/i},
  ejected: {regex: /Ejected/i, skip: true},

  deadball_rebound: {regex: /Deadball Team Rebound/, skip: true},
  off_rebound: {regex: /Offensive Rebound/, posession: true},
  def_rebound: {regex: /Defensive Rebound/, posession: true},
  jump_ball: {regex: /(Jump Ball|alternating possession)/i,
    posession: true},
}

# key: event_name, value: hash [key: txn, value: count]
transitions = Hash.new{|h,k| h[k] = Hash.new{|ha,ka| ha[ka] = 0}}

last_event_name = last_posessor = current_posession = nil
posessions = []

lines.each do |line|
  score, a_action, b_action, time = line.split("\t")
  a_score, b_score = score.split('-').map{|t| t.to_i}
  minutes, seconds = time.split(':').map{|t| t.to_i}
  seconds_left = minutes * 60 + seconds
  event_name = event = posessor = nil

  raise 'No actions' if a_action.empty? and b_action.empty?
  raise 'Two actions' if not a_action.empty? and not b_action.empty?

  action = a_action.empty? ? b_action : a_action
  actor = a_action.empty? ? :team_b : :team_a

  # find our defined action
  event_name, event = events.find {|name, event| event[:regex] =~ action}
  raise "No event found for #{action}" unless event_name
  next if event[:skip]

  posessor = actor if event[:posession]

  # has posession changed?
  if posessor and posessor != last_posessor
    if current_posession
      current_posession[:time] = current_posession[:left] - seconds_left
      posessions << current_posession if current_posession
    end
    current_posession = {
      team: actor,
      events: [],
      team_score: actor == :team_a ? a_score : b_score,
      opp_score: actor == :team_a ? b_score : a_score,
      left: seconds_left,
      points: 0}
    last_posessor = posessor
  end

  # we'll almost always have a current posession, but sometimes
  # we don't know until a few plays have happened
  if current_posession
    current_posession[:events] << event_name
    current_posession[:points] += event[:points] if event[:points]
  end

  transitions[last_event_name][event_name] += 1 if last_event_name
  last_event_name = event_name
end

current_posession[:time] = current_posession[:left]
posessions << current_posession

#transitions.each {|event, trans_map| puts "#{event}: #{trans_map}"}
puts posessions

puts '=' * 60
