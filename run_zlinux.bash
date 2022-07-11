#!/usr/bin/env bash

# Copyright 2022 by moshix
# sets up networking etc. and then IPLs zlinux
# Uses a provided Hercules environment and not any pre-installed version of Hercules

# v0.1 copied over a lot of stuff from installer script
# v0.2 fixed sudo stuff
# v0.3 fixed RAM calculation
# v0.4 more cleanup; remove unused, unnecessary, and broken code;
#      always exit with error status when exiting due to error.
# v0.5 use the Hercules config as it was created at install time, or later
#      modified by the user. Do not recalc CPU and RAM tuning.
# v0.6 use a Hercules build with a relative rpath set

version="0.5" # of zlinux system, not of this script
caller=""     # will contain the user name who invoked this script

who_called () {
    # establish which user called before sudo
    if [ $SUDO_USER ]; then caller=$SUDO_USER; else caller=`whoami`; fi
}

check_if_root () {
    # check if I am root
    if [ $SUDO_USER ]; then caller=$SUDO_USER; else caller=`whoami`; fi
    if [[ $caller == "root" ]]; then
        echo "${rev} ${red}You are root. There is no need to be root to run zlinux. Please run as a normal user...${reset}"
        exit 1
    fi
}

logit () {
    # log to file all messages
    logdate=`date "+%F-%T"`
    echo "$logdate:$1" >> ./logs/zLinux_runtime.log.$logdate
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

check_os () {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        echo
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        echo "${red}MacOS detected. Sorry, MacOS is not yet supported.${reset}"
        exit 1
    elif [[ "$OSTYPE" == "cygwin" ]]; then
        echo "${red}Cygwin detected. Sorry, Cygwin is not supported.${reset}"
        exit 1
    elif [[ "$OSTYPE" == "win32" ]]; then
        echo "${red}Windows detected. Sorry, Windows is not supported.${reset}"
        exit 1
    else
        echo "${red}Unrecognzied operating system. Exiting now.${reset}"
        exit 1
    fi
}

set_hercenv () {
    # set path to supplied hercules
    export PATH=./herc4x/bin:$PATH
}

run_sudo () {
    # are we running as sudo? If not inform user and exit
    arewesudo=`id -u`
    if [ $arewesudo  -ne 0 ]; then
        echo "${red}${rev} You need to execute this script with sudo or it won't work! ${reset}"
        exit 1
    fi
}

# main starts here

set_colors

who_called
logit "user invoking install script: $caller"

check_if_root # cannot be root
run_sudo      # must run with sudo (because of NAT setting)

# quick sanity checks
check_os

set_hercenv   # set paths for local herc4x hyperion instance

echo; echo; echo
logit "Starting zLinux "

# execute network configurator
./scripts/set_network

logdate=`date "+%F-%T"`
FILE=./logs/hercules.log.$logdate
HERCULES_RC=hercules.rc hercules -f hercules.cnf > $FILE

logit "Ending zlinux"

# moshix LICENSES THE LICENSED SOFTWARE "AS IS," AND MAKES NO EXPRESS OR IMPLIED
# WARRANTY OF ANY KIND. moshix SPECIFICALLY DISCLAIMS ALL INDIRECT OR IMPLIED
# WARRANTIES TO THE FULL EXTENT ALLOWED BY APPLICABLE LAW, INCLUDING WITHOUT
# LIMITATION ALL IMPLIED WARRANTIES OF, NON-INFRINGEMENT, MERCHANTABILITY, TITLE
# OR FITNESS FOR ANY PARTICULAR PURPOSE. NO ORAL OR WRITTEN INFORMATION OR ADVICE
# GIVEN BY moshix, ITS AGENTS OR EMPLOYEES SHALL CREATE A WARRANTY
