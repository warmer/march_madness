#!/usr/bin/env ruby

require 'yaml'

team = ARGV[0]

base_dir = File.dirname(File.dirname(File.expand_path(__FILE__)))
team_path = File.join(base_dir, 'scraped', team)

action_files = Dir.glob(File.join(team_path, 'actions-*.yml'))
raise "No actions found for team #{team}" unless action_files.length > 0

# transitions[in state][result] = number_of_times
transitions = Hash.new{|h,k| h[k] = Hash.new{|ha,ka| ha[ka] = 0}}
posessions = 0

action_files.each do |f|
  content = YAML::load(File.read(f).force_encoding('ASCII-8bit'))
  content.each do |seq|
    state = seq[:states].sort.join('-')
    result = seq[:points]
    transitions[state][result] += 1
  end
end

pos_avg = posessions * 1.0 / action_files.length

transitions.keys.sort.each do |name|
  actions = transitions[name]
  print "#{name.ljust(35, ' ')}"
  actions.keys.sort.each do |key|
    print "#{key} #{actions[key].to_s.rjust(3, ' ')}; "
  end
  print "\n"
end
