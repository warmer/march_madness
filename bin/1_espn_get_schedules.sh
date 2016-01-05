set -e

cat ../data/team_ids.tsv | while read team_id
do
  schedule=../data/schedules_$team_id.html
  game_list=../data/game_list_$team_id.tsv

  echo "Download the schedules for team ID $team_id"
  curl -s -S "http://espn.go.com/mens-college-basketball/team/schedule/_/id/$team_id" > $schedule

  echo "Scrape the game IDs from team ID $team_id's schedule"
  ./scrape.rb $schedule "<a\s+[^>]*href=['\"]/ncb/(?:recap|boxscore)\?gameId=(?<game_id>\d+)" > $game_list

  game_count=$(wc -l $game_list | grep -oP "^\d+")
  echo "Retrieved $game_count game IDs from $team_id"

  sleep 30
done

