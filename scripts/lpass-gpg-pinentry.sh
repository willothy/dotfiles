#!/bin/sh

# Implements pinentry protocol for GPG Agent

while read cmd
do
    case $cmd in
        GETPIN*)
            pass=$(lpass show --password "GPG Key")

            echo "D $pass"
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
