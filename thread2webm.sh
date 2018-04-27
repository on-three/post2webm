#!/bin/bash

TOOLS_DIR=tools

if [ "$#" -lt 1 ]; then
	echo "USAGE: $0  <url to 4chin thread> [-u: upload to mixtape.moe]"
	exit -1
fi

UPLOAD=false
if [ "$#" -gt 1 ]; then
UPLOAD=true
fi

#POST_URL=http://boards.4chan.org/tv/thread/91304338#p91304338POST_URL=$1
THREAD_URL=$1

#use /tmp/ as a working dir
WORKING_DIR=/tmp


# build a list of post numbers in a given thread
POST_LIST=`phantomjs ${TOOLS_DIR}/get_posts.js ${THREAD_URL} ${WORKING_DIR}`

if [ ! -f $POST_LIST ]; then
  echo "Post list file does not exist. FAILING"
  exit -1
fi

echo Generated post list at $POST_LIST

VIDEO_LIST=${POST_LIST}.videos.txt
rm -f ${VIDEO_LIST}
touch ${VIDEO_LIST}

BASENAME=$(basename "$POST_LIST" .txt)
THREAD_WEBM=${BASENAME}.webm

IFS=$'\n'
set -f
for POST_NUM in $(cat < ${POST_LIST}); do

  echo "Post in post list : ${POST_NUM}"

  POST_IMG=${WORKING_DIR}/${POST_NUM}.png
  POST_TXT=${WORKING_DIR}/${POST_NUM}.txt
  POST_AUDIO=${WORKING_DIR}/${POST_NUM}.mp3
  POST_VIDEO=${WORKING_DIR}/${POST_NUM}.mp4
  IMG_SIZE=1024x768
  NO_TEXT_DURATION_S=4

  # generate an image and textfile off the post
  if [ ! -f $POST_IMG ]; then
    phantomjs tools/get_post.js "$THREAD_URL" "$POST_NUM" "$WORKING_DIR"
    convert $POST_IMG -gravity center -background black -resize $IMG_SIZE -extent $IMG_SIZE $POST_IMG
  fi

  # fail if we don't have the resultant .png and .txt files
  if [ ! -f $POST_IMG ]; then
    echo "Post file does not exist. FAILING"
    exit -1
  fi

  # generate TTS audio
  if [ ! -f $POST_AUDIO ]; then
    if [ ! -f $POST_TXT ]; then
      ffmpeg -f lavfi -i anullsrc=channel_layout=stereo:sample_rate=24000 -t ${NO_TEXT_DURATION_S} ${POST_AUDIO}
    else
      gtts-cli -f ${POST_TXT} -o ${POST_AUDIO}
    fi
  fi

  AUDIO_LENGTH=`ffmpeg -i ${POST_AUDIO} 2>&1 |grep -oP "[0-9]{2}:[0-9]{2}:[0-9]{2}.[0-9]{2}"`
  echo Generated TTS audio file length: $AUDIO_LENGTH

  echo Generating video from image $POST_IMG

  #-video_track_timescale 29971 -ac 1
  #ffmpeg -y -loop 1 -i $POST_IMG -i $POST_AUDIO -c:a aac -ab 112k -c:v libx264 -shortest -strict -2 $POST_VIDEO
  echo ***** generating video off single post *****
  echo $POST_AUDIO
  echo $POST_IMG
  echo $POST_VIDEO
  ffmpeg -y -loop 1 -i $POST_IMG -i $POST_AUDIO -c:a aac -video_track_timescale 29971 -ac 1 -ab 112k -c:v libx264 -shortest -strict -2 ${POST_VIDEO}.tmp.mp4
  # reencode to a uniform format to ensure file sync
  ffmpeg -i ${POST_VIDEO}.tmp.mp4 -acodec libvo_aacenc -vcodec libx264 -s $IMG_SIZE -r 60 -strict experimental $POST_VIDEO

  # append created file to our list
  echo Added video $POST_VIDEO to $VIDEO_LIST
  #echo ${POST_VIDEO} >> $VIDEO_LIST
  echo file \'${POST_VIDEO}\' >> $VIDEO_LIST

done


#ffmpeg -f concat -safe 0 -i $VIDEOS_LIST -c copy ${THREAD_WEBM}.mp4
echo ******** generating video from video list $VIDEO_LIST *********
ffmpeg -y -f concat -safe 0 -i $VIDEO_LIST -c copy test.mp4


ffmpeg -y -i test.mp4 ${THREAD_WEBM}

if $UPLOAD ; then
  # upload to mixtape.moe
  #WEBM_URL=`uploadtomixtape.sh ${POST_WEBM}`
  echo $WEBM_URL
fi
