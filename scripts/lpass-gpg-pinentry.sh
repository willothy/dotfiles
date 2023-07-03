#!/bin/sh
# lpass-gpg-pinentry.sh

echo OK

while read cmd
do
    case $cmd in
	GETPIN*)
	    echo "D $(/usr/bin/lpass show --password "GPG Key")"
	    echo OK
	    ;;
	BYE*)
	    echo OK
	    exit 0
	    ;;
	*)
	    echo OK
	    ;;
    esac
done
