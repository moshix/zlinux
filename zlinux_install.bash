#!/usr/bin/env bash

# Copyright 2022 by moshix
# Installation script for S390x Ubuntu 18.04 .
# Does not necessarily work with prior or later version of Ubuntu.
# Obtains virgin ISO from Ubuntu, runs hercules-based install and then creates runtime environment.
# Uses a provided Hercules environment and not any pre-installed version of Hercules.

# v0.1 get location of ISO
# v0.2 inform user where it's being taken from
# v0.3 use scripts/ scripts to download, mount, create hdisk
# v0.4 Use our supplied hercules
# v0.5 detect OS and distro and block if not compatible
# v0.6 check for sudo
# v0.7 fix paths to relative not to userid relative (not ~./ )
# v0.8 auto-tune hercules.cnf
# v0.9 ask user to press enter to start hercules so they can see it will last a while
# v1.0 fix permissions
# v1.1 don't allow execution as user root
# v1.2 fixed RAM calculation
# v1.3 remove unused, unnecessary, and broken code;
#      always exist with error status when exiting due to error
# v1.4 do not leave directories without execute bit set
# v1.5 offer 27GB (3390-27) disk option; improve DASD creation

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
        echo "${rev} ${red}You are root. This installer must run with sudo, but not as root. Terminating...${reset}"
        exit 1
    fi
}

logit () {
    # log to file all messages
    logdate=`date "+%F-%T"`
    echo "$logdate:$1" >> ./logs/zLinux_installer.log.$logdate
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
        echo "${red}Unrecognized operating system. Exiting now.${reset}"
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
    sleep 3
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
        echo "${rev}${red} You have only ${cyan} $gbram ${red} in RAM in your system. That is not enough to install zLinux. Exiting now. ${reset}"
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

set_hercenv () {
    # set path to supplied hercules
    export PATH=./herc4x/bin:$PATH
    export LD_LIBRARY_PATH=./herc4x/lib:$LD_LIBRARY_PATH
    export LD_LIBRARY_PATH=./herc4x/lib/hercules:$LD_LIBRARY_PATH
}

run_sudo () {
    # are we running as sudo? If not inform user and exit
    arewesudo=`id -u`
    if [ $arewesudo  -ne 0 ]; then
        echo "${red}${rev} You need to execute this script with sudo or it won't work! ${reset}"
        exit 1
    fi
}

remove_env () {
    # this function checks if the environment file is there from previous run and
    # deletes it, if it is.
    local FILE=./tmp/herc_env
    rm $FILE
}

# main starts here
mkdir -p logs/
mkdir -p dasd/

set_colors

who_called
logit "user invoking install script: $caller"

check_if_root # cannot be root

run_sudo

remove_env

get_cores

get_ram

set_hercenv

echo
echo
echo "${green}    Starting zLinux installer Version $version ${reset}"
echo "${green}    ===================================== ${reset}"
echo
logit "Starting zLinux installer"

# quick sanity checks
check_os
get_distro

# ask user for disk size; loop until we get valid selection
diskvalid="no"
while [[ $diskvalid = "no" ]]; do
    read -p "${white}How big do you want your zLinux disk to be?  (3GB, 9GB, 27GB): ${reset} " dsize

    case "$dsize" in
    3*)
        echo "${yellow}Roger, ${cyan} 3GB  ${reset}"
        logit "user asked for 3GB DASD size"
        [ -e ./dasd/hd0.120 ] && rm -f dasd/hd0.120 # remove if it exists
        dasdinit64 -z ./dasd/hd0.120 3390-3 HD0 > logs/dasdinit.log 2> ./logs/dasddinit_error.log
        dasdresult=$?
        diskvalid="yes"
        ;;
    9*)
        echo "${yellow}Roger, ${cyan} 9GB ${reset}"
        logit "user asked for 9GB DASD size"
        [ -e ./dasd/hd0.120 ] && rm -f dasd/hd0.120 # remove if file already exists
        dasdinit64 -z ./dasd/hd0.120 3390-9 HD0 > logs/dasdinit.log 2> ./logs/dasddinit_error.log
        dasdresult=$?
        diskvalid="yes"
        ;;
    27*)
        echo "${yellow}Roger, ${cyan} 27GB ${reset}"
        logit "user asked for 27GB DASD size"
        [ -e ./dasd/hd0.120 ] && rm -f dasd/hd0.120 # remove if file already exists
        dasdinit64 -z ./dasd/hd0.120 3390-27 HD0 > logs/dasdinit.log 2> ./logs/dasddinit_error.log
        dasdresult=$?
        diskvalid="yes"
        ;;
    *)
        echo "${red}Unrecognized selection: $dsize. Try again and supply correct input, either 3GB, 9GB, or 27GB.${reset}"
        ;;
    esac

    if [[ $dasdresult -ne 0 ]]; then
        echo "${red}Error creating DASD file. Check logs/dasdinit.log and logs/dasdinit_error.log.${reset}"
        exit 1
done

# ask for confirmation before downloading iso....
read -p "${white}Continue with 700MB ISO download? (Y/N): " confirm && [[ $confirm == [yY] || $confirm == [yY][eE][sS] ]] || exit 1
echo "${reset}"
# user said it's ok to download. get iso
./scripts/getiso
# assume download succeded

#ask password for user zubuntu
./scripts/generpass

#create initrd
./scripts/create_initrd

# execute network configurator
./scripts/set_network

# place DVD IPL hercules.rc into working dir
rm -f ./hercules.rc
/bin/cp -rf ./assets/hercules.rc.DVD ./hercules.rc
chown $caller.$caller ./hercules.rc

# remove MAINSIZE and NUMCPU and MAXCPU from hercules.cnf
clean_conf

# attach rest of hercules.cnf (without MAINSIZE AND NUMCPU)
cat hercules.cnf >> /tmp/.hercules.cf1
mv /tmp/.hercules.cf1 hercules.cnf

echo "${yellow} Starting hercules with installation script now. Be patient. ${reset}"
read -p "${white} Please press ENTER to continue with install now. ${reset}" pressenter
# just giving user a chance to see
logdate=`date "+%F-%T"`
FILE=./logs/hercules.log.$logdate
hercules -f hercules.cnf > $FILE

# set correct permissions
who_called
chmod 644 ./dasd/hd0.120
chown $caller ./dasd/*
chown $caller.$caller ./hercules*
chmod 644 ./hercules*
chown $caller.$caller ./hercules*
chmod 644 ./logs/*
chmod -w ./assets/*
chown $caller *.iso*
chmod -w *.iso
chown -R $caller ./install/

echo "${yellow}It seems that the installation was successful. Start it with: ${reset}"
echo "${magenta}sudo ./run_zlinust.bash ${reset}"
echo
echo "${yellow}Good bye!${reset}"

# moshix LICENSES THE LICENSED SOFTWARE "AS IS," AND MAKES NO EXPRESS OR IMPLIED
# WARRANTY OF ANY KIND. moshix SPECIFICALLY DISCLAIMS ALL INDIRECT OR IMPLIED
# WARRANTIES TO THE FULL EXTENT ALLOWED BY APPLICABLE LAW, INCLUDING WITHOUT
# LIMITATION ALL IMPLIED WARRANTIES OF, NON-INFRINGEMENT, MERCHANTABILITY, TITLE
# OR FITNESS FOR ANY PARTICULAR PURPOSE. NO ORAL OR WRITTEN INFORMATION OR ADVICE
# GIVEN BY moshix, ITS AGENTS OR EMPLOYEES SHALL CREATE A WARRANTY
