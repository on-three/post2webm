#!/bin/bash


if [ "$#" -lt 1 ]; then
	echo "USAGE: $0  <url to 4chin post> [-u: upload to mixtape.moe]"
	exit -1
fi

UPLOAD=false
if [ "$#" -gt 1 ]; then
UPLOAD=true
fi

#POST_URL=http://boards.4chan.org/tv/thread/91304338#p91304338
POST_URL=$1

# get the post number off the url for bash regex
POST_NUM=91304338
regex="#p([0-9]+)$"
if [[ $POST_URL =~ $regex ]]
then
  POST_NUM=${BASH_REMATCH[1]}
else
  echo "Script currently only supports single #pXXX url style links off 4chin."
  exit -1
fi

echo Generating webm off post $POST_NUM on page at $POST_URL

#use /tmp/ as a working dir
WORKING_DIR=/tmp

POST_IMG=${WORKING_DIR}/${POST_NUM}.png
POST_TXT=${WORKING_DIR}/${POST_NUM}.txt
POST_AUDIO=${WORKING_DIR}/${POST_NUM}.mp3
POST_VIDEO=${WORKING_DIR}/${POST_NUM}.mp4
POST_WEBM=${POST_NUM}.webm
#IMG_SIZE=1024x768
IMG_SIZE=640X480
NO_TEXT_DURATION_S=4
# generate an image and textfile off the post
# there will ALWAYS be a POST_IMG afterwards but there may not be a POST_TXT
if [ ! -f $POST_IMG ]; then
  phantomjs tools/get_post.js "$POST_URL" "$WORKING_DIR"
  convert $POST_IMG -gravity center -background black -resize $IMG_SIZE -extent $IMG_SIZE $POST_IMG
fi

# fail if we don't have the resultant .png and .txt files
if [ ! -f $POST_IMG ]; then
  echo "Post img file does not exist. FAILING"
  exit -1
fi

# generate TTS audio or silence if there's no post text
if [ ! -f ${POST_AUDIO} ]; then
  if [ ! -f ${POST_TXT} ]; then
    #generate silence of N seconds for posts with no text
    ffmpeg -f lavfi -i anullsrc=channel_layout=stereo:sample_rate=24000 -t ${NO_TEXT_DURATION_S} ${POST_AUDIO}
  else
    # generate TTS audio of post via webservice.
    # TODO: randomize voices.
    gtts-cli -f ${POST_TXT} -o ${POST_AUDIO}
  fi
fi

AUDIO_LENGTH=`ffmpeg -i ${POST_AUDIO} 2>&1 |grep -oP "[0-9]{2}:[0-9]{2}:[0-9]{2}.[0-9]{2}"`
echo Generated TTS audio file length: $AUDIO_LENGTH

echo Generating video from image $POST_IMG
echo *** generating post video from txt and img***
echo $POST_AUDIO
echo $POST_IMG
echo $POST_VIDEO

ffmpeg -y -loop 1 -i $POST_IMG -i $POST_AUDIO -c:a aac -ab 112k -c:v libx264 -s $IMG_SIZE -shortest -strict -2 $POST_VIDEO

# TODO generate directly to webm
ffmpeg -y -i $POST_VIDEO $POST_WEBM

if $UPLOAD ; then
  # upload to mixtape.moe
  WEBM_URL=`uploadtomixtape.sh ${POST_WEBM}`
  echo $WEBM_URL
fi
