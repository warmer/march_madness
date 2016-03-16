set -e
set -x

#curl -s -S 'http://espn.go.com/mens-college-basketball/teams' > ../data/teams.html
#echo "Downloaded ../data/teams.html"



../bin/scrape.rb ../data/bracket.html "<dt>(?<high_seed>\d+) <a href=\"http://espn.go.com/mens-college-basketball/team/_/id/(?<high_seed_team_id>\d+)/[^\"]*\"[^>]*>[^<]*</a><br/>(?<low_seed>\d+) <a href=\"http://espn.go.com/mens-college-basketball/team/_/id/(?<low_seed_team_id>\d+)/[^\"]*\"[^>]*>[^<]*</a></dt>" > ../scraped/bracket.tsv
team_count=$(wc -l ../scraped/bracket.tsv | grep -oP "^\d+")
echo "Retrieved $team_count bracket games"
