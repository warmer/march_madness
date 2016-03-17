#!/usr/bin/env ruby

require 'yaml'

team_glob = ARGV[0] || '*'

base_dir = File.dirname(File.dirname(File.expand_path(__FILE__)))
team_paths = Dir.glob(File.join(base_dir, 'scraped', team_glob)).select{|p| p =~/\d+$/}

team_paths.each do |team_path|
  team = team_path.split('/').last

  puts team
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
      posessions += 1
    end
  end

  pos_avg = posessions * 1.0 / action_files.length

  #transitions.keys.sort.each do |name|
  #  actions = transitions[name]
  #  print "#{name.ljust(35, ' ')}"
  #  actions.keys.sort.each do |key|
  #    print "#{key} #{actions[key].to_s.rjust(3, ' ')}; "
  #  end
  #  print "\n"
  #end

  stats = {
    posession_num: pos_avg,
    transitions: transitions,
  }

  stat_file = File.join(team_path, 'stats.yml')
  File.write(stat_file, stats.to_yaml)
end
