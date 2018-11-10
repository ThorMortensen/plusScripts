#!/usr/bin/env bash



function checkAndSetIP_arg_masc(){
    if [ $# -ne 0 ]; then
        if [[ "$1" =~ ^[0-9]+$ ]] && [ "$1" -ge 0 -a "$1" -le 255 ]; then
        echo "New active device is $1";
        ruby ip_parser.rb $2 setActive $1
        else
        echo "Not a valid ip number [$1]. Must be 0 - 255"
        exit
        fi
    fi
}
