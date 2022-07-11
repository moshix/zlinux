#!/usr/bin/env bash

# Copyright 2022 by moshix
# cleanup script after successful install
# removes the following:
#   install/ directory
#   logs/ files relating to installation
#   removes the *.iso files (can be several files!)

# v0.3 clean up
# v0.4 no sudo required
# v0.5 consistent log file name for all messages during one run

version="0.5"

logextension=`date "+%F-%T"`
logit () {
    # log to file all messages
    logdate=`date "+%F-%T"`
    echo "$logdate:$1" >> ./logs/cleanup.log.$logextension
}

set_colors() {
    red=`tput setaf 1`
    green=`tput setaf 2`
    yellow=`tput setaf 3`
    blue=`tput setaf 4`
    magenta=`tput setaf 5`
    cyan=`tput setaf 6`
    white=`tput setaf 7`
    blink=`tput blink`
    rev=`tput rev`
    reset=`tput sgr0`
}

clean_stuff () {
    echo "${yellow}Cleanup Procedure ${reset}"
    echo
    sleep 1

    rm -fr install/
    rm -fr logs/install*
    rm -fr ./ubuntu-18.04.5-server-s390x.iso*

    echo "${yellow}All clean now! Goodbye. ${reset}"
    exit 0
}

# main starts here

set_colors

while true; do
    read -p "${white} Do you want to clean up your directory after a successful install? (y/n) ${reset}" runvar

    case "$runvar" in
    [Yy]*)
        echo "${yellow}Roger, cleaning it all up now... ${reset}"
        clean_stuff
        ;;
    [Nn]*)
        echo "${yellow}Ok, terminating now....  ${reset}"
        exit
        ;;
    *)
        echo "${red}Unrecognized selection: $runvar. y or n  ${reset}" ;;
    esac
done
