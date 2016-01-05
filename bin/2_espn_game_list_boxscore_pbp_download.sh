set -e

cat ../data/game_list_*.tsv | sort | uniq | while read line
do
  boxscore=../data/boxscore_$line.html
  playbyplay=../data/playbyplay_$line.html

  if [ ! -f $boxscore ]
  then
    curl -s -S "http://espn.go.com/mens-college-basketball/boxscore?gameId=$line" > $boxscore
    echo "Downloaded $boxscore"
    sleep 30
  fi
  if [ ! -f $playbyplay ]
  then
    curl -s -S "http://espn.go.com/mens-college-basketball/playbyplay?gameId=$line" > $playbyplay
    echo "Downloaded $playbyplay"
    sleep 30
  fi
done
