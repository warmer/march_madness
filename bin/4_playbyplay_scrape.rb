#!/usr/bin/env ruby

require 'yaml'
require 'json'
require 'fileutils'

files = ARGV[0] || 'playbyplay_*.html'

debug = false

DATA_DIR = File.expand_path(File.join(__FILE__, '../../data/'))
SCRAPED_DIR = File.join(File.dirname(DATA_DIR), 'scraped/')
raw_files = Dir.glob(File.join(DATA_DIR, files))

r1="<tr class=\"(?:even|odd)\"><td[^>]*>(?<time>[^<]*)</td>"
r1 += "<td[^>]*>(?:<b>|<B>)?(?:&nbsp;)?(?<team_a_action>[^<]*)(?:</b>|</B>)?</td>"
r1 += "<td[^>]*>(?<score>[^<]*)</td>"
r1 += "<td[^>]*>(?:<b>|<B>)?(?:&nbsp;)?(?<team_b_action>[^<]*)(?:</b>|</B>)?</td></tr>"

r2='<tr><td class="time-stamp">(?<time>[^>]*)</td><td[^>]*><img\s+class="[^"]*"\s+src="[^"]*/(?<team_id>\d+).png[^"]*"/></td><td[^>]*>(?<action>[^>]*)</td>(?:<!--(?:false|true)-->)?<td[^>]*>(?<score_away>\d+)\s*-\s*(?<score_home>\d+)</td><td[^>]*>[^<]*</td></tr>'

regex1 = Regexp.new(r1)
regex2 = Regexp.new(r2)
team_regex1 = Regexp.new('<h3><a href="http://espn.go.com/mens-college-basketball/team/_/id/(?<team_id>\d+)[^"]*">(?<team_name>[^<]*)</a>\s* <span>(?<team_score>\d*)</span></h3>')
team_regex2 = Regexp.new('<div class="team-info">(:?<span[^>]*>[^<]*</span>)?<a[ ]*(:?[a-zA-Z0-9_-]*[ ]*=[ ]*[^ ]*[ ]*)*href="/mens-college-basketball/team/_/id/(?<team_id>[0-9]+)"><span[^>]*>(?<team_name>[^<]*)')

def get_tokens(regex, content)
  res = []
  content.scan(regex) { res << $~ }
  res = res.map do |r|
    h = {}
    r.names.each do |name|
      val = r[name]
      val = val.gsub("\xE9", 'e')
      val = val.gsub("\xC3\xA9", 'e')
      h[name] = val
    end
    h
  end
  begin
    res = JSON.parse(res.to_json)
  rescue
    abort res.to_s
  end
  res
end

def convert_pbp(home, away, pbp)
  c = []
  converted = 0
  pbp.each do |p|
    if p['team_id']
      c << p
      next
    end

    a = {}
    a['action'] = p['team_a_action']
    a['team_id'] = away['team_id']
    if a['action'].empty?
      a['action'] = p['team_b_action']
      a['team_id'] = home['team_id']
    end
    a['time'] = p['time']
    a['score_away'], a['score_home'] = p['score'].split('-').map{|s| s.strip}
    c << a
    converted += 1
  end
  c
end

def save_stats(team_info, pbp, game_id)
  away = team_info[0]
  home = team_info[1]
  puts "# #{game_id} home: #{home['team_name']} [#{home['team_id']}], away: #{away['team_name']} [#{away['team_id']}]"
  stats = {
    home_team: home,
    away_team: away,
    game_id: game_id,
    play_by_play: convert_pbp(home, away, pbp),
  }
  statstr = stats.to_yaml
  home_path = File.join(SCRAPED_DIR, home['team_id'], "#{game_id}-vs-#{away['team_id']}.yml")
  away_path = File.join(SCRAPED_DIR, away['team_id'], "#{game_id}-at-#{home['team_id']}.yml")

  if not File.exist?(home_path)
    FileUtils.mkdir_p(File.dirname(home_path))
    File.write(home_path, statstr)
  end

  if not File.exist?(away_path)
    FileUtils.mkdir_p(File.dirname(away_path))
    File.write(away_path, statstr)
  end
end

valid = invalid_info = invalid_pbp = 0
raw_files.each do |filename|
  content = File.read(filename).force_encoding('ASCII-8bit')
  unless content.length > 0
    #File.delete(filename)
    puts "Deleting #{filename} (no content)"
  end

  team_info = []
  team_info_tokens = get_tokens(team_regex1, content)
  team_info_tokens = get_tokens(team_regex2, content) unless team_info_tokens.count == 2

  tokens = get_tokens(regex1, content)
  tokens = get_tokens(regex2, content) unless tokens.count > 0

  if tokens.count > 0 and team_info_tokens.count == 2
    #puts team_info_tokens.to_yaml
    #puts tokens.to_yaml
    valid += 1
    save_stats(team_info_tokens, tokens, filename.scan(/\d+/)[-1])
  else
    invalid_info += 1 if team_info_tokens.count != 0
    invalid_pbp += 1 if tokens.count == 0
    #puts "****#{filename.split('/')[-1]} no playbyplay"
  end
  print "Valid       : #{valid.to_s.rjust(4, ' ')} " if debug
  print "Invalid Info: #{invalid_info.to_s.rjust(4, ' ')} " if debug
  print "Invalid PBP : #{invalid_pbp.to_s.rjust(4, ' ')}\r" if debug
end
puts
puts "Valid       : #{valid}"
puts "Invalid Info: #{invalid_info.to_s.rjust(4, ' ')}"
puts "Invalid PBP : #{invalid_info.to_s.rjust(4, ' ')}"
