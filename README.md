zLinux Installer
================


This is a collection of scripts, recipes and stratagems to obtain an Ubuntu 18.04 ISO image for the s390x architecture, and then install it on an IBM 3390 virtual disk under Hercules. It was put together by Matthew Wilson and moshix over a period of a week or so.  

Features
========

| Hands-off installation  | :white_check_mark: |  
| Full network capability | :white_check_mark: |  
| Automatic routing       | :white_check_mark: |  
| Hercules binaries       | :white_check_mark: |  
| Teleportation support   | :x:                |  

  

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

As of July 2022 and as of Hyperion Hercules version 4.4.1, Ubuntu 18.04 is the latest version that can be IPLd. If you attempt to upgrade an existing Ubuntu 18.04 install to version 20.04 or higher, it will fail on IPL.  

By the same token, the last version of CentOS (or RHEL) that will IPL on the current Hercules is CentOS 7, or ClefOS 7.  

The reason for this is that later versions of Linux require special CPU instructions by the real iron mainframes of architecture level z12 and up, which Hyperion Hercules currently is not able to emulate. We don't expect a change in this situation any time soon. 


After Installation
==================

You will have Ubuntu/s390x installed in dasd/hd0.120

You can remove all unnecessary files by executing

>./cleanup_after_successful_install.bash



Racingmars/Moshix  
July 2022  
Portland, OR
