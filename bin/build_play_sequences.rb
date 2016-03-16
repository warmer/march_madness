#!/usr/bin/env ruby

require 'yaml'

file = ARGV[0]
raise 'Source file name not given' unless file
raise 'Source file does not exist' unless File.exist?(file)

game_id, visiting, opp_id = File.basename(file).split('.')[0].split('-')
team_id = File.basename(File.dirname(file))
team_is = (visiting == 'at') ? :away : :home

poss_file = File.join(File.dirname(file), "actions-#{game_id}-#{visiting}-#{opp_id}.yml")
if File.exists?(poss_file)
  print "#{poss_file} exists, skipping\r"
  exit 0
end

content = YAML::load(File.read(file).force_encoding('ASCII-8bit'))
pbp = content[:play_by_play]
exit 0 if pbp.count < 100

home_team = content[:home_team]['team_id']
away_team = content[:away_team]['team_id']

puts "Home: #{home_team}, Away: #{away_team}; #{team_id} is #{visiting} #{opp_id} (#{team_is})"

def time_sec(time_str)
  min, sec = time_str.split(':').map{|v| v.to_i}
  min * 60 + sec
end

plays = []

last_time = nil
pbp.each do |play|
  time = time_sec(play['time'])

  if last_time
    if time < last_time
      # decreasing - correct order
      plays = pbp.dup
      break
    elsif time > last_time
      # increasing - reverse order
      plays = pbp.dup.reverse
      break
    end
  end

  last_time = time
end

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
  made_two_ft: {regex: /made 2 Free Throws/, posession: true, points: 2},

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

  timeout: {regex: /Timeout/, posession: true},
  end_of_half: {regex: /End of/, skip: true},
}

last_event_name = last_posessor = current_posession = nil
posessions = []

# NOTE: second and overtime periods behave the same for now
TIME_STATES = [
  {name: :opening,        time_left: 2400 - 300},
  {name: :first_meat,     time_left: 2400 - 900},
  {name: :first_end,      time_left: 1200},
  {name: :opening2,       time_left: 1200 - 300},
  {name: :second_meat,    time_left: 300},
  {name: :second_end,     time_left: 180},
  {name: :second_crunch,  time_left: 0},
]
DIFF_STATES = [
  {name: :big_trouble,    diff: -20}, # more than 20 pts behind
  {name: :trouble,        diff: -10}, # 11-20 points behind
  {name: :small_trouble,  diff: -4},  # 5-10 points behind
  {name: :tiny_down,      diff: 0},   # 1-4 points behind
  {name: :tied,           diff: 1},   # tied
  {name: :tiny_up,        diff: 5},   # 1-4 ahead
  {name: :small_lead,     diff: 11},  # 5-10 points ahead
  {name: :lead,           diff: 21},  # 11-20 points ahead
  {name: :big_lead,       diff: 999}, # more than 20 points ahead
]

def time_state(seconds_left)
  state = TIME_STATES[0]
  TIME_STATES.each do |s|
    if s[:time_left].to_i <= seconds_left.to_i
      state = s
      break
    end
  end
  state[:name]
end

def diff_state(diff)
  state = nil
  DIFF_STATES.each do |s|
    if s[:diff] > diff
      state = s
      break
    end
  end
  state[:name]
end

first_half = true
score_home = score_away = score_home = score_away = 00
posessor = nil

plays.each do |play|
  score_home = play['score_home'].to_i
  score_away = play['score_away'].to_i
  minutes, seconds = play['time'].split(':').map{|t| t.to_i}
  seconds_left = minutes * 60 + seconds
  action = play['action']
  actor = (play['team_id'] == home_team ? :home : :away)

  # find our defined action
  event_name, event = events.find {|name, event| event[:regex] =~ action}
  raise "No event found for #{action}" unless event_name
  next if event[:skip]

  posessor = actor if event[:posession]

  # has posession changed?
  if posessor and posessor != last_posessor
    # we've been tracking a posession
    if current_posession
      current_posession[:time] = current_posession[:left] - seconds_left
      current_posession[:left] += 1200 if first_half

      if current_posession[:time] < 0
        first_half = false
        current_posession[:time] += 1200
      end

      diff = score_home - score_away
      diff = diff * -1 if posessor == :home
      current_posession[:states] = [
        time_state(current_posession[:left]),
        diff_state(diff),
      ]

      # proper account of starting points
      pts_to_sub = events[current_posession[:events][0]][:points] || 0
      current_posession[:team_score] -= pts_to_sub

      posessions << current_posession
    end

    current_posession = {
      team: actor,
      events: [],
      team_score: actor == :home ? score_home : score_away,
      opp_score: actor == :home ? score_away : score_home,
      left: seconds_left,
      points: 0}
    last_posessor = posessor
  end

  # we'll almost always have a current posession, but sometimes
  # we don't know until a few plays have happened at the beginning of a game
  if current_posession
    current_posession[:events] << event_name
    current_posession[:points] += event[:points] if event[:points]
  end

  last_event_name = event_name
end

diff = score_home - score_away
diff = diff * -1 if posessor == :home
current_posession[:states] = [
  time_state(current_posession[:left]),
  diff_state(diff),
]

current_posession[:time] = current_posession[:left]
posessions << current_posession

# fix the time taken in the first posession
posessions[0][:time] = [2400 - posessions[0][:left], 0].max

team_sequences = posessions.select{|p| p[:team] == team_is}

File.write(poss_file, team_sequences.to_yaml)

