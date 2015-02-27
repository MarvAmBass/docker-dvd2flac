#!/bin/bash

cd /rips/

###
#
# VARIABLES
#
###

# get complete dvd info
#mplayer -vo null -ao null -endpos 0 dvd:// -identify 2> /dev/null

# get name of this DVD
DVD_NAME=`mplayer -vo null -ao null -endpos 0 dvd:// -identify 2> /dev/null | grep ID_DVD_VOLUME_ID | cut -d"=" -f2`

# get dvd id
DVD_ID=`mplayer -vo null -ao null -endpos 0 dvd:// -identify 2> /dev/null | grep ID_DVD_DISC_ID | cut -d"=" -f2`

# get number of audio streams
DVD_NUMOF_AUDIO=`mplayer -vo null -ao null -endpos 0 dvd:// -identify 2> /dev/null | grep "audio stream:" | wc -l`

# get number of titles
DVD_NUMOF_TITLES=`mplayer -vo null -ao null -endpos 0 dvd:// -identify 2> /dev/null | grep "DVD_TITLES" | cut -d"=" -f2`

# get info about audio streams
DVD_INFO_AUDIO=`mplayer -vo null -ao null -endpos 0 dvd:// -identify 2> /dev/null | grep "audio stream:" | sed 's/\.$/\n/g'`

# get info about titles their chapters and lenghts
DVD_INFO_VIDEO=`mplayer -vo null -ao null -endpos 0 dvd:// -identify 2> /dev/null | grep "DVD_TITLE_" | sort | sed 's/^.*.ANGLES.*.$/ /g'`

###
#
# WAIT FOR DVD
#
###

#if [ $DVD_NUMOF_AUDIO -gt 0 ]
if [ 1 -gt 0 ]
then
	echo " DVD found :)"
else
	echo -n "..."
	sleep 3
	./$0
	exit 0
fi

###
#
# START
#
###

mkdir dvd/
cd dvd/

clear

echo "$DVD_NAME - ($DVD_ID)"
echo ""
echo "$DVD_NUMOF_TITLES title/s found - $DVD_NUMOF_AUDIO audio stream/s found"
echo ""
echo ""
echo "################"
echo "#####TITLES#####"
echo "################"
echo "$DVD_INFO_VIDEO"
echo ""
echo "################"
echo "#####AUDIO######"
echo "################"
echo ""
echo "$DVD_INFO_AUDIO"
echo ""
echo ""

echo "################"
echo "################"
echo ""

read -p "enter the title nuber you want to rip as audio: " USER_TITLE

echo ""
echo "title $USER_TITLE will be ripped as audio"
USER_TITLE_NUMOF_CHAPTERS=`mplayer -vo null -ao null -endpos 0 dvd:// -identify 2> /dev/null | grep "DVD_TITLE" | grep "CHAPTERS" | grep _$USER_TITLE\_ | cut -d"=" -f2` # get number of chapters of a title
echo "title $USER_TITLE has $USER_TITLE_NUMOF_CHAPTERS chapters"
echo ""

if [ -d "$DVD_NAME" ] ; then 
        echo "found directory $DVD_NAME..."
        WORKING_DIR=$DVD_NAME-`date +%Y.%m.%d-%H.%M.%S`
else
        WORKING_DIR=$DVD_NAME
fi

echo "using $WORKING_DIR as working directory"
mkdir "$WORKING_DIR"
cd "$WORKING_DIR"
echo ""

echo "################"
echo "######TAGS######"
echo "################"
echo ""

echo "you'll be asked for the following:"
echo ""

echo "ARTIST (Composer)"
echo "ALBUM"
echo "GENRE"
echo "PERFORMER"
echo "DATE"

echo ""
echo "################"
echo ""

# set tag file variable
FILE_PREVIOUS_TAGS="../../dvd-previous-tags.txt"

if [ -e "$FILE_PREVIOUS_TAGS" ]
then
	source "$FILE_PREVIOUS_TAGS"
	echo "loaded tags from file $FILE_PREVIOUS_TAGS"
fi

read -p "enter the ARTIST: [$TAG_ARTIST] " TAG_MAN_ARTIST
read -p "enter the ALBUM: [$TAG_ALBUM] " TAG_MAN_ALBUM
read -p "enter the GENRE: [$TAG_GENRE] " TAG_MAN_GENRE
read -p "enter the PERFORMER: [$TAG_PERFORMER] " TAG_MAN_PERFORMER
read -p "enter the DATE: [$TAG_DATE] " TAG_MAN_DATE

if [ ! -z "$TAG_MAN_ARTIST" ]
then
        TAG_ARTIST=$TAG_MAN_ARTIST
fi

if [ ! -z "$TAG_MAN_ALBUM" ]
then
        TAG_ALBUM=$TAG_MAN_ALBUM
fi

if [ ! -z "$TAG_MAN_GENRE" ]
then
        TAG_GENRE=$TAG_MAN_GENRE
fi

if [ ! -z "$TAG_MAN_PERFORMER" ]
then
        TAG_PERFORMER=$TAG_MAN_PERFORMER
fi

if [ ! -z "$TAG_MAN_DATE" ]
then
        TAG_DATE=$TAG_MAN_DATE
fi

echo "save tags to file $FILE_PREVIOUS_TAGS"
# clear/reset tags file
echo "# file only for sourcing into srv-dvd2music.sh!"> $FILE_PREVIOUS_TAGS
echo "TAG_ARTIST=\"$TAG_ARTIST\"" >> $FILE_PREVIOUS_TAGS
echo "TAG_ALBUM=\"$TAG_ALBUM\"" >> $FILE_PREVIOUS_TAGS
echo "TAG_GENRE=\"$TAG_GENRE\"" >> $FILE_PREVIOUS_TAGS
echo "TAG_PERFORMER=\"$TAG_PERFORMER\"" >> $FILE_PREVIOUS_TAGS
echo "TAG_DATE=\"$TAG_DATE\"" >> $FILE_PREVIOUS_TAGS

echo ""
echo ""

echo "cd $TAG_ARTIST"
mkdir "$TAG_ARTIST"
cd "$TAG_ARTIST"
echo ""

echo "cd ($TAG_DATE) $TAG_ALBUM"
mkdir "($TAG_DATE) $TAG_ALBUM"
cd "($TAG_DATE) $TAG_ALBUM"
echo ""

for((i=0; i<$USER_TITLE_NUMOF_CHAPTERS; i++))
do
        RIP_START=$(($i+1))
        RIP_END=$(($i+1))

        echo "ripping track $RIP_START / $USER_TITLE_NUMOF_CHAPTERS"
        mplayer -vc null -vo null -ao pcm:fast:waveheader:file="$RIP_START.wav" dvd://$USER_TITLE -chapter $RIP_START-$RIP_END  2> /dev/null > /dev/null
        echo "done"
        echo ""
done

echo "all done"
echo ""
echo ""

echo "converting wav to flac"
flac *.wav > /dev/null # 2> /dev/null
echo "done"
echo ""

if [ $(ls -l *.flac | wc -l) -gt 0 ]
then
	echo "remove wav"
	rm *.wav > /dev/null 2> /dev/null
	echo "done"
else
	echo "no flacs found! - didn't remove wavs"
	echo "waiting... enter 5 characters to continue..."
	read -n 5
fi
echo ""
echo ""

echo "start tagging"
echo ""

for((y=0; y<$USER_TITLE_NUMOF_CHAPTERS; y++))
do
        RIP_START=$(($y+1))

        echo "tagging track $RIP_START / $USER_TITLE_NUMOF_CHAPTERS"
        metaflac --set-tag="TRACKNUMBER=$RIP_START" $RIP_START.flac
        metaflac --set-tag="ISRC=$DVD_ID" $RIP_START.flac        
        metaflac --set-tag="ARTIST=$TAG_ARTIST" $RIP_START.flac        
        metaflac --set-tag="ALBUM=$TAG_ALBUM" $RIP_START.flac        
        metaflac --set-tag="GENRE=$TAG_GENRE" $RIP_START.flac        
        metaflac --set-tag="PERFORMER=$TAG_PERFORMER" $RIP_START.flac        
        metaflac --set-tag="DATE=$TAG_DATE" $RIP_START.flac        
        echo "done"
        echo ""
done

echo "done tagging"
