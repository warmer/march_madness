set -e

curl -s -S 'http://espn.go.com/mens-college-basketball/teams' > ../data/teams.html
echo "Downloaded ../data/teams.html"

../bin/scrape.rb ../data/teams.html "<a\s+[^>]*href=['\"]?http://espn.go.com/mens-college-basketball/team/_/id/(?<team_id>\d+)/[^'\"\s]*['\"]?[^>]*>\s*([^<]*?)\s*</a>" > ../data/team_ids.tsv
team_count=$(wc -l ../data/team_ids.tsv | grep -oP "^\d+")
echo "Retrieved $team_count team IDs"
