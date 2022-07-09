#!/usr/bin/env bash

# Copyright 2022 by moshix
# installation sceripot for S390x Ubuntu 18.04 
# does not necessarily work with prior or later version of Ubuntu
# Obtains virign ISO from Ubuntu, runs hercules-based install and then creates runtime environment
# Uses a provided Hercules environment and not any pre-installed version of Hercules

# v0.1 get location of ISO
# v0.2 inform user where it's being taken from
# v0.3 use scripts/ scripot to download, mount, create hdisk 
# v0.4 Use our supplied hercules
# v0.5 detect OS and distro and block if not compatible
# v0.6 check for sudo
# v0.7 fix paths to relative not to userid relative (not ~./ )
# v0.8 auto-tune hercules.cnf
# v0.9 ask user to press enter to start hercules so they can see it will last a while
# v1.0 fix permissions
# v1.1 don't allow execution as user root


version="0.2" #of zlInux system, not of this script
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

	if [ $cores \> 5 ]; then
		        intcores=5
	fi


	if [ $cores \> 7 ]; then
		        intcores=6
	fi

	if [ $cores \< 3 ]; then
		        intcores=2
	fi

	if [ $cores \< 2 ]; then
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
	# this function set a sensible amount of RAM for the tkbuntu instance
	bkram=`grep MemTotal /proc/meminfo | awk '{print $2}'  `
	let "gbram=$bkram/1024"

	if ((  $gbram < 1300 )); then
		 echo "${red} You have only ${cyan} $gbram ${red} in RAM in your system. That is not enough to stat tkbuntu. Exiting now. ${reset}"
		  exit
	fi

	if ((  gbram > 8000 )); then
		hercram=4096
	fi

	if (( $gbram <  8192 )) && ((  $gbram >  6000 )); then
		hercram=4096
	fi

	if (( $gbram >  3000 ))  &&  (( $gbram < 5999 )); then
		hercram=2048
	fi

	if (( $gbram < 2200 )); then
		hercram=1024
	fi

	if (( $gbram > 16000  )); then
		hercram=8192
	fi


	echo "${yellow}RAM in KB  ${cyan} $gbram. ${yellow}Setting Hercules to ${cyan} $hercram  ${reset}"
	echo  "MAINSIZE     $hercram" >> ./tmp/herc_env
	logit "MAINSIZE     $hercram"
	echo "MAINSIZE         $hercram"  >> /tmp/.hercules.cf1
}


clear_conf () {
[-e ./hercules.rc ] && /bin/cp -rf ./assets/hercules.rc.ipl.hd0 ./hercules.rc
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

run_sudo () {
	# are we running as sudo? If not inform user and exit
arewesudo=`id -u`
if [ $arewesudo  -ne 0 ]; then 
	echo "${red}${rev} You need to execute this script sudo or it wont' work! ${reset}"
	exit
fi
}

remove_env () {
	# this function checks if the environment file is there from previous run and 
	# deletes it, if it is. 
	local FILE=./tmp/herc_env
	rm $FILE
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

# set path to  supplied hercules
export PATH=./herc4x/bin:$PATH
export LD_LIBRARY_PATH=./herc4x/lib:$LD_LIBRARY_PATH
export LD_LIBRARY_PATH=./herc4x/lib/hercules:$LD_LIBRARY_PATH


echo " "                                                                        
echo " "                                                                        
echo "${green}    Starting zLinux installer Version $version ${reset}"
echo "${green}    ===================================== ${reset}"
echo " "
logit "Starting zLinux installer"

# quick sanity checks
check_os
get_distro

#ask user for disk size
read -p "${white}How big do you want your zLinux disk to be?  (3GB, 9GB): ${reset} " dsize

case "$dsize" in
  3*) 
	  echo "${yellow}Roger, ${cyan} 3GB  ${reset}" 
	  logit "user asked for 3GB DASD size "
	  [ -e ./dasd/hd0.120 ] && rm -f dasd/hd0.120 # remove if it exists
	  dasdinit64 -bz2 ./dasd/hd0.120 3390-3 HD0 > logs/dasdinit.log 2> ./logs/dasddinit_error.log;;
  9*)   
	  echo "${yellow}Roger, ${cyan} 9GB ${reset}" 
	  logit "user asked for 9GB DASD size"
	  [ -e ./dasd/hd0.120 ] && rm -f dasd/hd0.120 # remove if file already exists
	  dasdinit64 -bz2 ./dasd/hd0.120 3390-9 HD0 > logs/dasdinit.log 2> ./logs/dasddinit_error.log;;
  *) 
	  echo "${red}Unrecognized selection: $dsize. Restart and supply correct input, either 3GB or 9GB... ${reset}" 
	  exit 1;;
esac



# ask for confirmation before downloading iso....
read -p "${white}Continue with 700MB ISO download? (Y/N): " confirm && [[ $confirm == [yY] || $confirm == [yY][eE][sS] ]] || exit 1
echo "${reset}"
#user said it's ok to download. get iso 
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


# remove MAINSIZE AND NUMCPU AND MAXCPU from hercules.cnf
clean_conf


# attach rest of hercules.cnf (without MAINSIZE AN NUMCPU)
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
chmod -R 644 ./install



# now ask user if to run the newly created image or if to exit
while true; do
read -p "${white} Do you want to run Hercules with the newly installed zLinux now? (y/n) ${reset}" runvar

  case "$runvar" in
     [Yy]*)
          echo "${yellow}Ok, restarting now Hercules and IPLing from DASD... ${reset}" 
	  logit "user asked to immediately start hercules with new DASD after install"
          /bin/cp -f ./assets/hercules.rc.hd0 hercules.rc
          logdate=`date "+%F-%T"`
	  FILE=./logs/hercules.log.$logdate
          hercules -f hercules.cnf > $FILE   
          ;;
     [Nn]* )
          echo "${yellow}Ok, terminating now....  ${reset}" 
          # restore path variables to before we got executed by firing squad
	  unset PATH
	  unset LD_LIBRARY_PATH
          export PATH=$oldpath
          export LD_LIBRARY_PATH=$oldldpath
          exit;;
     *)
          echo "${red}Unrecognized selection: $runvar. y or n  ${reset}" ;;
  esac
done

# ask if to clean up after successful install
./cleanup_after_successful_install.bash

# moshix LICENSES THE LICENSED SOFTWARE "AS IS," AND MAKES NO EXPRESS OR IMPLIED 
# WARRANTY OF ANY KIND. moshix SPECIFICALLY DISCLAIMS ALL INDIRECT OR IMPLIED 
# WARRANTIES TO THE FULL EXTENT ALLOWED BY APPLICABLE LAW, INCLUDING WITHOUT 
# LIMITATION ALL IMPLIED WARRANTIES OF, NON-INFRINGEMENT, MERCHANTABILITY, TITLE
# OR FITNESS FOR ANY PARTICULAR PURPOSE. NO ORAL OR WRITTEN INFORMATION OR ADVICE
# GIVEN BY moshix, ITS AGENTS OR EMPLOYEES SHALL CREATE A WARRANTY
exit

