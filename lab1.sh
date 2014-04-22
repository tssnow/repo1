#!/bin/bash

TOSEARCH=/root/labs/medialab/media.xml
FILES=$(ls /root/labs/medialab)
COUNT=0

for ITEM in $FILES
do
	if [ $ITEM = media.xml ] ;then
		continue
	fi
	if ! grep -q $ITEM $TOSEARCH ;then
		echo $ITEM
		((COUNT++))
	fi
done
echo "$COUNT files not found"
	
