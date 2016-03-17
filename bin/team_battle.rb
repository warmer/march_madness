#!/usr/bin/env ruby

require 'yaml'
require_relative '../lib/common.rb'

class TeamBattle
  def initialize(team_a, team_b, iterations)
    $team_a = team_a
    $team_b = team_b
    $iterations = iterations
  end

  def run
    debug "#{$team_a} is playing #{$team_b}"
    base_dir = File.dirname(File.dirname(File.expand_path(__FILE__)))
    team_a_path = File.join(base_dir, 'scraped', $team_a)
    team_b_path = File.join(base_dir, 'scraped', $team_b)

    stats_a_file = File.join(team_a_path, 'stats.yml')
    stats_b_file = File.join(team_b_path, 'stats.yml')

    raise "No stats found for team #{$team_a}" unless File.exists?(stats_a_file)
    raise "No stats found for team #{$team_b}" unless File.exists?(stats_b_file)

    stats_a = YAML::load(File.read(stats_a_file).force_encoding('ASCII-8bit'))
    stats_b = YAML::load(File.read(stats_b_file).force_encoding('ASCII-8bit'))

    posession_time_a = (2400 / stats_a[:posession_num].to_f).to_i
    posession_time_b = (2400 / stats_b[:posession_num].to_f).to_i

    win_a = win_b = score_a = score_b = 0
    $iterations.times do |itr|
      time_left = 2400
      score_a = score_b = 0
      posession = :team_b

      loop do
        ts = time_state(time_left)
        if posession == :team_a
          time_left -= (posession_time_a / 2)
          diff = score_a - score_b
          ds = diff_state(diff)
          points = points_for(stats_a[:transitions], $team_a, ds, ts)
          score_a += points
          # update score
          posession = :team_b
        else
          time_left -= (posession_time_b / 2)
          diff = score_b - score_a
          ds = diff_state(diff)
          points = points_for(stats_b[:transitions], $team_b, ds, ts)
          score_b += points
          # update score
          posession = :team_a
        end

        debug "#{time_left / 60}:#{time_left % 60}, #{$team_a}: #{score_a} - #{$team_b}: #{score_b}"
        if time_left <= 0
          break if score_a != score_b
          debug 'Overtime!'
          time_left = 300
        end
      end

      if score_a > score_b
        win_a += 1
      else
        win_b += 1
      end
    end
    {$team_a => win_a, $team_b => win_b, score_a: score_a, score_b: score_b}
  end

  private

  def debug(line = '')
    #puts line
  end

  def state_for(stats, ds, ts)
    ds_orig = ds
    ts_orig = ts
    state = nil
    loop do
      state = [ts, ds].sort.join('-')
      point_stats = stats[state]
      break if point_stats
      idx = 0
      DIFF_STATES.each_with_index do |s|
        if s[:name] == ds
          break
        end
        idx += 1
      end
      if idx == DIFF_STATES.count / 2
        rando_state = stats.keys.select{|k| k =~ /#{ts}/}.sample
        debug "FUDGING DIFF STATE to #{rando_state} - not enough data for #{ds_orig}/#{ts_orig}!"
        return rando_state
      end
      idx += 1 if idx < DIFF_STATES.count / 2
      idx -= 1 if idx > DIFF_STATES.count / 2
      ds = DIFF_STATES[idx][:name]
      debug " >> fudging diff state to #{ds}"
    end
    state
  end

  def points_for(stats, team, ds, ts)
    state = state_for(stats, ds, ts)
    point_stats = stats[state]

    index = Random.rand(point_stats.values.inject(:+))
    points = nil
    point_stats.each do |pts, count|
      if count > index
        points = pts
        break
      end
      index -= count
    end
    points
  end
end

if __FILE__ == $0
  team_a = ARGV[0]
  team_b = ARGV[1]
  iterations = (ARGV[2] || '1').to_i

  battle = TeamBattle.new(team_a, team_b, iterations)
  results = battle.run

  puts "### RESULT ### #{results}"
end

