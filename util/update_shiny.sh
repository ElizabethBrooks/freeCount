#!/bin/bash

# List of server IPs
SERVERS=(
"149.165.172.236"
"149.165.170.219"
"149.165.170.22"
"149.165.171.54"
"149.165.171.216"
"149.165.175.91"
"149.165.175.54"
"149.165.174.200"
"149.165.175.191"
"149.165.168.25"
"149.165.169.120"
"149.165.174.245"
"149.165.172.11"
"149.165.169.117"
)

# Commands to run to update version
CMD1="cd /srv/shiny-server/"
CMD2="sudo rm -Rf freeCount"
CMD3="sudo git clone https://github.com/ElizabethBrooks/freeCount.git"
CMD4="cd freeCount/apps/"
CMD5='for f in *; do sudo mkdir ${f%.R}; sudo chmod o+x $f; sudo mv $f ${f%.R}/app.R; done'
CMD6="cd /srv/shiny-server/freeCount/apps/"
CMD7="sudo chown -R shiny ."
CMD8="sudo chgrp -R shiny ."


# Loop through each server and execute the commands
for SERVER in "${SERVERS[@]}"; do
  echo "Executing on $SERVER..."
  ssh exouser@$SERVER "
    echo 'Running CMD1: $CMD1'; $CMD1
    echo 'Running CMD2: $CMD2'; $CMD2
    echo 'Running CMD3: $CMD3'; $CMD3
    echo 'Running CMD4: $CMD4'; $CMD4
    echo 'Running CMD5: $CMD5'; $CMD5
    echo 'Running CMD6: $CMD6'; $CMD6
    echo 'Running CMD7: $CMD7'; $CMD7
    echo 'Running CMD8: $CMD8'; $CMD8
  "
  echo "Finished executing on $SERVER"
  echo "---------------------------------"
done
