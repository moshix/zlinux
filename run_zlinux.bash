#!/usr/bin/env bash

# Copyright 2022 by moshix
# set ups networking etc. and then IPLs zlinux
# Uses a provided Hercules environment and not any pre-installed version of Hercules

# v0.1 copied over a lot of stuff from installer script


version="0.3" #of zlinux system, not of this script
caller=""     # will contain the user name who invoked this script


who_called () {
# establish which user called before sudo 
if [ $SUDO_USER ]; then caller=$SUDO_USER; else caller=`whoami`; fi
}

check_if_root () {
# check if I am root
if [ $SUDO_USER ]; then caller=$SUDO_USER; else caller=`whoami`; fi
if [[ $caller == "root" ]]; then
	echo "${rev} ${red}You are root. There is no need to be root to run zlinux. Please as a normal user...${reset}"
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
        echo "  "
elif [[ "$OSTYPE" == "darwin"* ]]; then
        echo "${red}Macos detected. Sorry, Macos is not yet supported.{$reset}"
        exit
elif [[ "$OSTYPE" == "cygwin" ]]; then
        echo "${red}Cygwin detected. Sorry, Cygwin is not supported.{$reset}"
        exit
elif [[ "$OSTYPE" == "win32" ]]; then
        echo "${red}Windows detected. Sorry, Windows is not supported.{$reset}"
        exit
        # I'm not sure this can happen.
elif [[ "$OSTYPE" == "freebsd"* ]]; then
         echo "${red}FreeBSD detected. Sorry, FreeBSD  is not yet supported.{$reset}"
        exit
else
        echo "${red}Unrecognzied operating system. Exiting now.{$reset}"
        exit
fi
} 


get_distro() {
if [ -f /etc/os-release ]; then
    # freedesktop.org and systemd
    . /etc/os-release
    OS=$NAME
    VER=$VERSION_ID
elif type lsb_release >/dev/null 2>&1; then
    # linuxbase.org
    OS=$(lsb_release -si)
    VER=$(lsb_release -sr)
elif [ -f /etc/lsb-release ]; then
    # For some versions of Debian/Ubuntu without lsb_release command
    . /etc/lsb-release
    OS=$DISTRIB_ID
    VER=$DISTRIB_RELEASE
elif [ -f /etc/debian_version ]; then
    # Older Debian/Ubuntu/etc.
    OS=Debian
    VER=$(cat /etc/debian_version)
elif [ -f /etc/SuSe-release ]; then
    # Older SuSE/etc.
    ...
elif [ -f /etc/redhat-release ]; then
    # Older Red Hat, CentOS, etc.
    ...
else
    # Fall back to uname, e.g. "Linux <version>", also works for BSD, etc.
    OS=$(uname -s)
    VER=$(uname -r)
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
	echo  "NUMCPU       $intcores" >> ./tmp/herc_env
	echo  "MAXCPU       $intcores" >> ./tmp/herc_env
	logit "NUMCPU       $intcores"
	logit "MAXCPU       $intcores"
	# below to start to prepare new hercules.cnf 
	echo "NUMCPU           $intcores"  > /tmp/.hercules.cf1
	echo "MAXCPU           $intcores"  >> /tmp/.hercules.cf1
}

get_cpu() {
	cputype=`cat /proc/cpuinfo`
}

get_ram ()  {
	# this function set a sensible amount of RAM for the Ubuntu/s390x installation procedure
	bkram=`grep MemTotal /proc/meminfo | awk '{print $2}'  `
	let "gbram=$bkram/1024"

	if ((  $gbram < 1300 )); then
et_hercenv	 echo "${rev}${red} You have only ${cyan} $gbram ${red} in RAM in your system. That is not enough to IPL  zLinux. Exiting now. ${reset}"
		  exit
	fi

        if [ $gbram -gt 16000 ]; then
                hercram=8192
        elif [ $gbram -gt 8192  ]; then
		hercram=4096

	elif [ $gbram <  8192 ] && [  $gbram >  6000 ]; then
		hercram=4096

	elif [ $gbram >  3000 ]  &&  [ $gbram < 5999 ]; then
		hercram=2048
	
	elif [ $gbram < 2200 ]; then
		hercram=1024
        fi

	echo "${yellow}RAM in KB  ${cyan} $gbram. ${yellow}Setting Hercules to ${cyan} $hercram  ${reset}"
	echo  "MAINSIZE     $hercram" >> ./tmp/herc_env
	logit "MAINSIZE     $hercram"
	echo "MAINSIZE         $hercram"  >> /tmp/.hercules.cf1
}

set_hercenv () {
	# set path to  supplied hercules
	export PATH=./herc4x/bin:$PATH
	export LD_LIBRARY_PATH=./herc4x/lib:$LD_LIBRARY_PATH
	export LD_LIBRARY_PATH=./herc4x/lib/hercules:$LD_LIBRARY_PATH

}

clear_conf () {
/bin/cp -rf ./assets/hercules.rc.ipl.hd0 ./hercules.rc
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
        echo "${red}${rev} You need to execute this script sudo or it wont' work! ${reset}"
        exit
fi
}

# main starts here

oldpath=`echo $PATH`               # needed so we can use supplied Hercules
oldldpath=`echo $LD_LIBRARY_PATH`

set_colors

who_called
logit "user invoking install script: $caller"

check_if_root # cannot be root

run_sudo 

remove_env

get_cores

get_ram

set_hercenv  #set paths for local herc4x hyperion instance

echo " "                                                                        
echo " "                                                                        
echo " "
logit "Starting zLinux "

# quick sanity checks
check_os
get_distro


# execute network configurator
./scripts/set_network


# attach rest of hercules.cnf (without MAINSIZE AN NUMCPU)
cat hercules.cnf >> /tmp/.hercules.cf1
mv /tmp/.hercules.cf1 hercules.cnf


# remove MAINSIZE AND NUMCPU AND MAXCPU from hercules.cnf and copy hercules.rc into place
clean_conf

# copy correct .rc file 
clear_conf 

# just giving user a chance to see
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
exit

