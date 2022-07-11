#!/usr/bin/env bash

# Copyright 2022 by moshix
# sets up networking etc. and then IPLs zlinux
# Uses a provided Hercules environment and not any pre-installed version of Hercules

# v0.1 copied over a lot of stuff from installer script
# v0.2 fixed sudo stuff
# v0.3 fixed RAM calculation
# v0.4 more cleanup; remove unused, unnecessary, and broken code;
#      always exit with error status when exiting due to error.

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

get_cores () {
    # tune CPU number
    cores=`grep -c ^processor /proc/cpuinfo`
    intcores=1

    if [[ $cores -gt 7 ]]; then
        intcores=6
    elif [[ $cores -gt 5 ]]; then
        intcores=5
    elif [[ $cores -gt 3 ]]; then
        intcores=2
    else
        intcores=1
    fi

    # now put in config file
    echo "${yellow}Number of cores present ${cyan} $cores. ${yellow}Setting Hercules to ${cyan} $intcores ${reset}"

    sleep 2
    echo  "NUMCPU       $intcores" >> ./tmp/herc_env
    echo  "MAXCPU       $intcores" >> ./tmp/herc_env
    logit "NUMCPU       $intcores"
    logit "MAXCPU       $intcores"
    # below to start to prepare new hercules.cnf
    echo "NUMCPU           $intcores"  > /tmp/.hercules.cf1
    echo "MAXCPU           $intcores"  >> /tmp/.hercules.cf1
}

get_ram ()  {
    # this function sets a sensible amount of RAM for the Ubuntu/s390x installation procedure
    bkram=`grep MemTotal /proc/meminfo | awk '{print $2}'`
    let "gbram=$bkram/1024"

    if [[ $gbram -lt 1300 ]]; then
        echo "${rev}${red} You have only ${cyan} $gbram ${red} in RAM in your system. That is not enough to IPL zLinux. Exiting now. ${reset}"
        exit 1
    elif [[ $gbram -lt 2200 ]]; then
        hercram=1024
    elif [[ $gbram -lt 6000 ]]; then
        hercram=2048
    elif [[ $gbram -lt 16000 ]]; then
        hercram=4096
    else
        hercram=8192
    fi

    echo "${yellow}RAM in KB ${cyan}${gbram}.${yellow}Setting Hercules to ${cyan}${hercram}${reset}"
    echo "MAINSIZE      $hercram" >> ./tmp/herc_env
    logit "MAINSIZE     $hercram"
    echo "MAINSIZE      $hercram" >> /tmp/.hercules.cf1
}

set_hercenv () {
    # set path to supplied hercules
    export PATH=./herc4x/bin:$PATH
    export LD_LIBRARY_PATH=./herc4x/lib:$LD_LIBRARY_PATH
    export LD_LIBRARY_PATH=./herc4x/lib/hercules:$LD_LIBRARY_PATH
}

clear_conf () {
    /bin/cp -rf ./assets/hercules.rc.hd0 ./hercules.rc
}

clean_conf () {
    # remove MAINSIZE, MAXCPU and NUMCPU from hercules.cnf file
    # so we can then add the auto-tuned values before starting hercules
    sed '/^MAINSIZE/d' hercules.cnf > ./tmp/.hercules.cnfc
    sed '/^NUMCPU/d' ./tmp/.hercules.cnfc > ./tmp/.hercules.cnfd
    sed '/^MAXCPU/d' ./tmp/.hercules.cnfd > ./tmp/.hercules.cnfe
    mv ./tmp/.hercules.cnfe hercules.cnf
    rm ./tmp/.hercules.cnfc
    rm ./tmp/.hercules.cnfd
}

remove_env () {
    # this function checks if the environment file is there from previous run and
    # deletes it, if it is.
    local FILE=./tmp/herc_env
    rm $FILE
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

oldpath=`echo $PATH`               # needed so we can use supplied Hercules
oldldpath=`echo $LD_LIBRARY_PATH`

set_colors

who_called
logit "user invoking install script: $caller"

check_if_root # cannot be root

run_sudo      # must run with sudo (because of NAT setting)

remove_env

# quick sanity checks
check_os

# remove MAINSIZE and NUMCPU and MAXCPU from hercules.cnf and copy hercules.rc into place
clean_conf

get_cores     # autotune CP for hercules.cnf

get_ram       # autotune RAM

set_hercenv   #set paths for local herc4x hyperion instance

echo
echo
echo
logit "Starting zLinux "

# execute network configurator
./scripts/set_network

# attach rest of hercules.cnf (without MAINSIZE and NUMCPU)
cat hercules.cnf >> /tmp/.hercules.cf1
mv /tmp/.hercules.cf1 hercules.cnf
chown $caller.$caller hercules.cnf

# copy correct .rc file
clear_conf
chown $caller.$caller hercules.rc

export HERCULES_RC=hercules.rc
logdate=`date "+%F-%T"`
FILE=./logs/hercules.log.$logdate
hercules -f hercules.cnf > $FILE

logit "Ending zlinux"

# moshix LICENSES THE LICENSED SOFTWARE "AS IS," AND MAKES NO EXPRESS OR IMPLIED
# WARRANTY OF ANY KIND. moshix SPECIFICALLY DISCLAIMS ALL INDIRECT OR IMPLIED
# WARRANTIES TO THE FULL EXTENT ALLOWED BY APPLICABLE LAW, INCLUDING WITHOUT
# LIMITATION ALL IMPLIED WARRANTIES OF, NON-INFRINGEMENT, MERCHANTABILITY, TITLE
# OR FITNESS FOR ANY PARTICULAR PURPOSE. NO ORAL OR WRITTEN INFORMATION OR ADVICE
# GIVEN BY moshix, ITS AGENTS OR EMPLOYEES SHALL CREATE A WARRANTY
