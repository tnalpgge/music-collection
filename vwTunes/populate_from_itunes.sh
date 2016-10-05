#!/bin/sh
IPOD_MOUNTPOINT=$HOME/mnt/iPod
export IPOD_MOUNTPOINT
ITUNES_LIBRARY="$HOME/Music/iTunes/iTunes Music/Music"
export ITUNES_LIBRARY
perl bin/initialize.pl
perl bin/extract.pl vwTunes >bar.txt
perl bin/add.pl @bar.txt
perl bin/vwTunes.pl
du -sh $IPOD_MOUNTPOINT
