#!/bin/sh

username='willothyh@gmail.com'

status=$(lpass status)

if [ $? -ne 0 ]
then
    if [ "$status" = 'Not logged in.' ]
    then
	# Make sure DISPLAY is set
	DISPLAY=${DISPLAY:-:0} lpass login "$username" 1>&2
    else
	echo "Lastpass error: $status" 1>&2
	exit 1
    fi
fi

lpass $@
