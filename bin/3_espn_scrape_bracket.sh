set -e
set -x

bracket_html=../data/bracket.html
bracket_tsv=../scraped/bracket.tsv

curl -s -S 'http://espn.go.com/mens-college-basketball/tournament/bracket' > ../data/bracket.html
echo "Downloaded $bracket_html"

../bin/scrape.rb $bracket_html "<dt>(?<high_seed>\d+) <a href=\"http://espn.go.com/mens-college-basketball/team/_/id/(?<high_seed_team_id>\d+)/[^\"]*\"[^>]*>[^<]*</a><br/>(?<low_seed>\d+) <a href=\"http://espn.go.com/mens-college-basketball/team/_/id/(?<low_seed_team_id>\d+)/[^\"]*\"[^>]*>[^<]*</a></dt>" > $bracket_tsv
team_count=$(wc -l $bracket_tsv | grep -oP "^\d+")
echo "Retrieved $team_count bracket games"
