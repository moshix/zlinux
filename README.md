<a href="https://hits.seeyoufarm.com"><img src="https://hits.seeyoufarm.com/api/count/incr/badge.svg?url=https%3A%2F%2Fgithub.com%2Fmoshix%2Fzlinux&count_bg=%2379C83D&title_bg=%23555555&icon=&icon_color=%23E7E7E7&title=hits&edge_flat=false"/></a>
[![View SBOM](https://img.shields.io/badge/sbom.sh-viewSBOM-blue?link=https%3A%2F%2Fsbom.sh%2F10cf520f-2e95-4b9d-9066-c8bdc718efef)](https://sbom.sh/10cf520f-2e95-4b9d-9066-c8bdc718efef)
  
zLinux Installer
================


This is a collection of scripts, recipes and stratagems to obtain an Ubuntu 18.04 ISO image for the s390x architecture, and then install it on an IBM 3390 virtual disk under Hercules. It was put together by Matthew Wilson and moshix over a period of a week or so.  

:tada: Just launch the script, have yourself a nice cup of coffee, and return to a fully installed Ubuntu/s390x system!

Features
========

| Feature                    | Supported          |
| -------------------------- | ------------------ |
| Hands-off installation     | :white_check_mark: |  
| Automatic ISO download     | :white_check_mark: |  
| Automagic DASD creation    | :white_check_mark: |  
| Full network capability    | :white_check_mark: |  
| Automatic network routing  | :white_check_mark: |  
| Hercules binaries included | :white_check_mark: |  
| Windows host               | :x:                |  

  

Installation
============

Start the installer by doing:

>./zlinux_install.bash

The script will proceed to download Ubuntu 18.0.4-5 for s390x ISO to your local machine.  

It will then ask you to pick a password for the user "zubuntu" on the new system.

After that it will automatically start an up-to-date Hercules emulator (which is provided with this repo) and run the full Ubuntu 18.04 server installation procedure, fully automated. No user interaction is needed for the complete installaton.  

The installation can take 90 minutes to 2 hours, depending on the speed of your machine.  


A standard server Ubuntu 18.04 will be installed with an ssh server, so you will be able to ssh into Linux. 


Operation
=========

After the successful install, you start Ubuntu by running the following script:

>./run_zlinux.bash

Once Linux has finished booting, it has full connectivity to the Internet (thru NAT) and you can ssh into the user zubuntu by doing:

>ssh zubuntu@10.1.1.2

and provide the password you specified for this user during installation.

Everything else is just normal Linux; i.e. you can run apt-get, etc., etc.

A few things to know about the generated Ubuntu instance that will IPL from DASD after the install:

>Internal IP:   10.1.1.2  
>IP of gateway: 10.1.1.1  
>DNS server:    1.1.1.1  
>user name:     zubuntu/password as set up by you during installation process  

The s/390x Linux instance will connect through a tunnel interface which is set up by the the run_zlinux.bash script in this directory. It then further uses NAT on your default NIC interface to connect to the Internet.



Why Ubuntu 18.04
================

As of June 2023 and as of Hyperion Hercules version 4.6, Ubuntu 18.04 is the newest version that can be IPLd on Hercules. If you attempt to upgrade an existing Ubuntu 18.04 install to version 20.04 or higher, it will fail on IPL.  

By the same token, the last version of CentOS (or RHEL) that will IPL on the current Hercules is CentOS 7, or ClefOS 7.  

The reason for this is that later versions of Linux require special CPU instructions by the real iron mainframes of architecture level z12 and up, which Hyperion Hercules currently is not able to emulate. At the time of this writing, we don't expect a change in this situation any time soon. 


After Installation
==================

You will have Ubuntu/s390x installed in dasd/hd0.120

You can remove all unnecessary files by executing

>./cleanup_after_successful_install.bash



Racingmars/Moshix    
June, 2023  

