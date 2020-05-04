#!/bin/bash

MAX_TRIES=10
SLEEP_TIME=20

API_ONLINE=0

TRY=0
echo "Wait for the API with $TRY tries and wait sleep for $SLEEP_TIME seconds"
while [ $TRY -le $MAX_TRIES ]
do
    echo "Try number: $TRY"
    curl --location 'http://localhost:3000/api' --header 'Content-Type: application/json' --header 'Authorization: Basic YWRtaW46YWRtaW4='
    if [ $? -eq 0 ]
    then
        echo "API online"
        API_ONLINE=1
        exit 0
    fi
    TRY=$(( TRY + 1 ))
    echo "Sleep for $SLEEP_TIME"
    sleep $SLEEP_TIME
done

if (( $API_ONLINE == 0 ))
then
    echo "API is still not online"
    exit 1
fi

echo 
curl --location --request PATCH 'http://localhost:3000/api/manage/user/1/' \
--header 'Content-Type: application/json' \
--header 'Authorization: Basic YWRtaW46YWRtaW4=' \
--data-raw '{
    "id": 1,
    "scan_directory": "/data"
}'

echo
curl --location --request GET 'http://localhost:3000/api/scanphotos/' \
--header 'Authorization: Basic YWRtaW46YWRtaW4='

TRY=0
PHOTO_COUNT=0
echo "Check photo count with $TRY tries and wait sleep for $SLEEP_TIME seconds"
while [ $TRY -le $MAX_TRIES ]
do
    echo "Try number: $TRY"
    PHOTO_COUNT=$(curl --location --request GET 'http://localhost:3000/api/photos/recentlyadded/' --header 'Authorization: Basic YWRtaW46YWRtaW4=' | jq .count)
    if (( $PHOTO_COUNT > 0 ))
    then
        echo "Photo count greater than 1"
        break
    fi
    TRY=$(( TRY + 1 ))
    echo "Sleep for $SLEEP_TIME"
    sleep $SLEEP_TIME
done

if (( $PHOTO_COUNT == 0 )); then
    echo "Photo count is 0, should be greater than 0"
    exit 1
fi

TRY=0
INFERRED_COUNT=0
echo "Check inferred count with $TRY tries and wait sleep for $SLEEP_TIME seconds"
while [ $TRY -le $MAX_TRIES ]
do
    echo "Try number: $TRY"
    INFERRED_COUNT=$(curl -s --location --request GET 'http://localhost:3000/api/faces/inferred/list/' --header 'Authorization: Basic YWRtaW46YWRtaW4=' | jq .count)
    if (( $INFERRED_COUNT > 0 ))
    then
        echo "Inferred count greater than 1"
        break
    fi
    TRY=$(( TRY + 1 ))
    echo "Sleep for $SLEEP_TIME"
    sleep $SLEEP_TIME
done

if (( $INFERRED_COUNT == 0 )); then
    echo "Inferred count is 0, should be greater than 0"
    exit 1
fi