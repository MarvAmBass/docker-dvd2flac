#!/bin/sh

RIPS="$PWD/rips"

mkdir -p "$RIPS" &> /dev/null

docker rm -f dvd2flac

docker run \
-ti --rm \
--privileged \
-v /etc/localtime:/etc/localtime:ro \
-v /dev/sr0:/dev/dvd \
-v $RIPS:/rips \
--name dvd2flac marvambass/dvd2flac
