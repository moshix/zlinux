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
# v1.6 switch to template-based preseed and hercules.cnf creation
# v1.7 use a Hercules build with a relative rpath set
# v1.8 run as regular user, only using sudo when necessary
# v1.9 detect successful installation
# v1.10 misc fixes:
#         put all log messages for this run in same log file
#         fixup permissions of set_network log
#         dasdinit log typo
#         rename assets directory to templates
# v1.11 Make sure we have the route command available before we go too far
# v1.12 Syntax improvements, better logging
# v1.13 remove requirement for net-tools

source ./Version

# This is the command we will use when we need superuser privileges. It is
# exported so scripts we call will also use this value. If you use "doas" you
# may change it here.
SUDO="sudo -E"
export SUDO

test_sudo () {
#    echo "${yellow}Testing if '$SUDO' command works ${reset}"
    if [[ $($SUDO id -u) -ne 0 ]]; then
        echo "${rev}${red}$SUDO did not set us to uid 0; you must run this script with a user that has $SUDO privileges.${reset}"
        exit 1
    fi
}

check_if_root () {
    # check if I am root and terminate if so
    if [[ $(id -u) -eq 0 ]]; then
        echo "${rev}${red}You are root. You must run this installer as a regular user. Terminating...${reset}"
        exit 1
    fi
}

logextension=`date "+%F-%T"`
logit () {
    # log to file all messages
    logdate=`date "+%F-%T"`
    echo "$logdate:$1" >> ./logs/zLinux_installer.log."$logextension"
}

set_colors() {
    red=`tput setaf 1`
    green=`tput setaf 2`
    yellow=`tput setaf 3`
    blue=`tput setaf 4`
    magenta=`tput setaf 5`
    cyan=`tput setaf 6`
    white=`tput setaf 7`
    bold=`tput bold`
    uline=`tput smul`
    blink=`tput blink`
    rev=`tput rev`
    reset=`tput sgr0`
}

check_os () {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        echo
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        echo "${rev}${red}MacOS detected. Sorry, MacOS is not yet supported.${reset}"
        exit 1
    elif [[ "$OSTYPE" == "cygwin" ]]; then
        echo "${rev}${red}Cygwin detected. Sorry, Cygwin is not supported.${reset}"
        exit 1
    elif [[ "$OSTYPE" == "win32" ]]; then
        echo "${rev}${red}Windows detected. Sorry, Windows is not supported.${reset}"
        exit 1
    else
        echo "${rev}${red}Unrecognized operating system. Exiting now.${reset}"
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

    echo "${yellow}Number of cores present ${cyan} $cores. ${yellow}Setting Hercules to ${cyan} $intcores ${reset}"
    sleep 2
}

get_ram () {
    # this function sets a sensible amount of RAM for the Ubuntu/s390x installation procedure
    bkram=`grep MemTotal /proc/meminfo | awk '{print $2}'`
    let "gbram=$bkram/1024"

    if [[ $gbram -lt 1300 ]]; then
        echo "${rev}${red}You have only ${cyan} $gbram ${red} in RAM in your system. That is not enough to install zLinux. Exiting now. ${reset}"
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

    echo "${yellow}RAM in KB ${cyan}${gbram}. ${yellow}Setting Hercules to ${cyan}${hercram}${reset}"
    sleep 2
}

set_hercenv () {
    # set path to supplied hercules
    export PATH=./herc4x/bin:$PATH
}

create_conf () {
    cp templates/hercules.cnf.template hercules.cnf
    chmod +w hercules.cnf
    sed -i "s/__CPU__/$intcores/" hercules.cnf
    sed -i "s/__RAM__/$hercram/" hercules.cnf
}

check_already_installed () {
    if [[ -f install_success ]]; then
        logit "there is already an install_success file"
        echo "${yellow}It appears you have already completed a successful installation."
        echo -n "Do you really want to start over? (Y/N):${reset} "
        read startover
        [[ "$startover" == [yY] || "$startover" == [yY][eE][sS] ]] || exit 1
        logit "user chose to overwrite current installation"
        rm -f install_success
    fi
}

# main starts here

set_colors
# are we running from the zlinux directory (instead of higher or lower directory?)
cpwd=`pwd`
curdir=`basename "$cpwd"`

if [[ "$curdir"  != "zlinux" ]]; then
	echo "${rev}${red}This script needs to be executed from inside the zlinux directory. Please retry. ${red}"
	exit 1
fi


mkdir -p logs/
mkdir -p dasd/


check_if_root # cannot be root
logit "user invoking install script: $(whoami)"

check_already_installed

test_sudo     # but we must have sudo capability

# quick sanity checks
check_os

get_cores
get_ram
create_conf

set_hercenv

echo
echo
echo "${green}    Starting zLinux installer Version $version ${reset}"
echo "${green}    ===================================== ${reset}"
echo
logit "Starting zLinux installer"

# ask user for disk size; loop until we get valid selection
diskvalid="no"
while [[ $diskvalid = "no" ]]; do
    read -p "${white}Please input desired zLinux disk size:  (3GB, 9GB, 27GB): ${reset} " dsize

    case "$dsize" in
    3*)
	# test if there is at least 3GB of disk space
        FREE=`df -k --output=avail "$PWD" | tail -n1`
        if [[ $FREE -lt 4545728 ]]; then               # 3G = 3*1024*1024k + ISO + copy_of_ISO
           echo "${rev}${red}Sorry you don't have enough disk space. Terminating now... ${reset}"   # less than 10GBs free!
           exit 1
        fi
        echo "${yellow}Roger, ${cyan} 3GB  ${reset}"
        logit "user asked for 3GB DASD size"
        [ -e ./dasd/hd0.120 ] && rm -f dasd/hd0.120 # remove if it exists
        dasdinit64 -z ./dasd/hd0.120 3390-3 HD0 > logs/dasdinit.log 2> ./logs/dasdinit_error.log
        dasdresult=$?
        diskvalid="yes"
        ;;
    9*)
        FREE=`df -k --output=avail "$PWD" | tail -n1` 
        if [[ $FREE -lt 10837184 ]]; then               # 9G = 9*1024*1024k + IS + copy_of_ISO
           echo "${rev}${red}Sorry you don't have enough disk space. Terminating now... ${reset}"   # less than 10GBs free!
           exit 1
        fi
        echo "${yellow}Roger, ${cyan} 9GB ${reset}"
        logit "user asked for 9GB DASD size"
        [ -e ./dasd/hd0.120 ] && rm -f dasd/hd0.120 # remove if file already exists
        dasdinit64 -z ./dasd/hd0.120 3390-9 HD0 > logs/dasdinit.log 2> ./logs/dasdinit_error.log
        dasdresult=$?
        diskvalid="yes"
        ;;
    27*)
        FREE=`df -k --output=avail "$PWD" | tail -n1`  
        if [[ $FREE -lt 29711552 ]]; then               # 27G = 27*1024*1024k + ISO  + copy_of_ISO!!
           echo "${rev}${red}Sorry you don't have enough disk space. Terminating now... ${reset}"   # less than 10GBs free!
           exit 1
        fi
        echo "${yellow}Roger, ${cyan} 27GB ${reset}"
        logit "user asked for 27GB DASD size"
        [ -e ./dasd/hd0.120 ] && rm -f dasd/hd0.120 # remove if file already exists
        dasdinit64 -z ./dasd/hd0.120 3390-27 HD0 > logs/dasdinit.log 2> ./logs/dasdinit_error.log
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
    fi
done

# ask for confirmation before downloading iso....
read -p "${white}Continue with 700MB ISO download? (Y/N): " confirm && [[ $confirm == [yY] || $confirm == [yY][eE][sS] ]] || exit 1
echo "${reset}"
# user said it's ok to download. get iso
./scripts/getiso || exit 1

# Get user password and embed the preseed file into the initrd for install
./scripts/config_preseed

# execute network configurator
$SUDO ./scripts/set_network
$SUDO chown $(id -u):$(id -g) ./logs/setnetwork.log*

# The hercifc util needs to be setuid root to manage network interface. We will
# copy the as-installed copy, which is owned by the user and not root, so that
# we can restore the original owner and permissions after Hercules is done.
# But we won't overwrite an existing backup, in case previous runs failed and
# we're starting again
if [[ ! -f herc4x/bin/hercifc.orig ]]; then
    cp herc4x/bin/hercifc herc4x/bin/hercifc.orig
fi
$SUDO chown root:root herc4x/bin/hercifc
$SUDO chmod +s herc4x/bin/hercifc

# copy correct .rc file for installation
cp templates/hercules.rc.DVD hercules.rc
chmod +w hercules.rc   # ...just in case, for easy replacement later

echo "${yellow}Starting hercules with installation script now. Be patient. ${reset}"
read -p "${white}Please press ENTER to continue with install now. ${reset}" pressenter
# just giving user a chance to see
logdate=`date "+%F-%T"`
FILE=./logs/hercules.log.$logdate
$SUDO HERCULES_RC=hercules.rc hercules -f hercules.cnf > "$FILE"

logit "finished hercules run"
# After hercules finishes, restore the original hercifc
# This is for two reasons: less time leaving a suid binary sitting around,
# and make it easier for the user to clean up later by "rm -rf ..." this
# entire directory and not run into problems deleting a file owned by root.
if [[ -f herc4x/bin/hercifc.orig ]]; then
    $SUDO rm -f herc4x/bin/hercifc
    mv herc4x/bin/hercifc.orig herc4x/bin/hercifc
fi

if [[ ! -f install_success ]]; then
    logit "install determined to be a failure!!!!!"	
    echo "${rev}${red}It seems Hercules quit before the installation finished successfully."
    echo "Check for errors in the logs in logs/, and try running the installation script again.${reset}"
    exit 1
fi

# copy the correct hercules.rc for future use
cp templates/hercules.rc.hd0 hercules.rc


logit "Successful install! Yesh!"
echo "${yellow}It seems that the installation was successful. Start it with: ${reset}"
echo "${magenta}./run_zlinux.bash ${reset}"
echo
echo "${yellow}Good bye!${reset}"

logit "zlinux_install is now quitting"

# moshix LICENSES THE LICENSED SOFTWARE "AS IS," AND MAKES NO EXPRESS OR IMPLIED
# WARRANTY OF ANY KIND. moshix SPECIFICALLY DISCLAIMS ALL INDIRECT OR IMPLIED
# WARRANTIES TO THE FULL EXTENT ALLOWED BY APPLICABLE LAW, INCLUDING WITHOUT
# LIMITATION ALL IMPLIED WARRANTIES OF, NON-INFRINGEMENT, MERCHANTABILITY, TITLE
# OR FITNESS FOR ANY PARTICULAR PURPOSE. NO ORAL OR WRITTEN INFORMATION OR ADVICE
# GIVEN BY moshix, ITS AGENTS OR EMPLOYEES SHALL CREATE A WARRANTY
