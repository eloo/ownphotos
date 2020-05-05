#!/bin/bash

function exitWithLog() 
{
    echo "ownphotos.log"
    docker exec -it ownphotos-backend bash -c "cat /code/logs/ownphotos.log"

    echo "gunicorn_image_similarity.log"
    docker exec -it ownphotos-backend bash -c "cat /code/logs/gunicorn_image_similarity.log"

    echo "rqworker.log"
    docker exec -it ownphotos-backend bash -c "cat /code/logs/rqworker.log"
    exit "$1"
}

MAX_TRIES=10
SLEEP_TIME=20

API_ONLINE=0

TRY=0
echo "Wait for the API with $TRY tries and wait sleep for $SLEEP_TIME seconds"
while [ $TRY -le $MAX_TRIES ]
do
    echo "Try number: $TRY"
    curl -si --location 'http://localhost:3000/api/user' --header 'Content-Type: application/json' --header 'Authorization: Basic YWRtaW46YWRtaW4=' | grep "200 OK"
    if [ $? -eq 0 ]
    then
        echo "API online"
        API_ONLINE=1
        break
    fi
    TRY=$(( TRY + 1 ))
    echo "Sleep for $SLEEP_TIME seconds"
    sleep $SLEEP_TIME
done

if (( API_ONLINE == 0 ))
then
    echo "API is still not online"
    exitWithLog 1
fi


echo
echo "Set data directory" 
curl -s --location --request PATCH 'http://localhost:3000/api/manage/user/1/' \
--header 'Content-Type: application/json' \
--header 'Authorization: Basic YWRtaW46YWRtaW4=' \
--data-raw '{
    "id": 1,
    "scan_directory": "/data"
}'
echo

echo
echo "Trigger scan"
curl -s --location --request GET 'http://localhost:3000/api/scanphotos/' \
--header 'Authorization: Basic YWRtaW46YWRtaW4='
echo

TRY=0
PHOTO_COUNT=0
echo
echo "Check photo count with $TRY tries and wait sleep for $SLEEP_TIME seconds"
while [ $TRY -le $MAX_TRIES ]
do
    echo "Try number: $TRY"
    PHOTO_COUNT=$(curl -s --location --request GET 'http://localhost:3000/api/photos/recentlyadded/' --header 'Authorization: Basic YWRtaW46YWRtaW4=' | jq .count)
    if (( PHOTO_COUNT > 0 ))
    then
        echo "Photo count greater than 1"
        break
    fi
    TRY=$(( TRY + 1 ))
    echo "Sleep for $SLEEP_TIME seconds"
    sleep $SLEEP_TIME
done

if (( PHOTO_COUNT == 0 )); then
    echo "Photo count is 0, should be greater than 0"
    exitWithLog 1
fi

TRY=0
LABELED_COUNT=0
echo
echo "Check labeled count with $TRY tries and wait sleep for $SLEEP_TIME seconds"
while [ $TRY -le $MAX_TRIES ]
do
    echo "Try number: $TRY"
    LABELED_COUNT=$(curl -s --location --request GET 'http://localhost:3000/api/faces/labeled/list/' --header 'Authorization: Basic YWRtaW46YWRtaW4=' | jq .count)
    if (( LABELED_COUNT > 0 ))
    then
        echo "Labeled count greater than 1"
        break
    fi
    TRY=$(( TRY + 1 ))
    echo "Sleep for $SLEEP_TIME seconds"
    sleep $SLEEP_TIME
done

if (( LABELED_COUNT == 0 )); then
    echo "Inferred count is 0, should be greater than 0"
    exitWithLog 1
fi

echo
echo "Check jobs"
JOBS=$(curl -s --location --request GET 'http://localhost:3000/api/jobs' --header 'Authorization: Basic YWRtaW46YWRtaW4=')
jq . <<< "$JOBS"

FINISHED=$(jq ".results[].finished" <<< "$JOBS")
if [ ! "$FINISHED" = "true" ]; then
  echo "The job is not finished: $FINISHED"
  exitWithLog 1
fi

exitWithLog 0