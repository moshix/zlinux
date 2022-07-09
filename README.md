zLinux Installer
================


This is a collection of scripts, recipees and strategems to obtain an Ubuntu 18.04 iso image for the s390x architecture, and then install it on fresh DASD 3390 virtual disk under Hercules. 

You just execute the the installer by doing:

>sudo ./zlinux_install.bash

and everything else is interactive. 


Operation
=========

A standard Ubuntu 18.04 will be installed. It will have full connectivty to the Internet (thru NAT) and you can ssh into the user zubuntu by doing:

>ssh zubuntu@10.1.12 

and provide the password you specified for this user during installation. 

Everything else is just normal Linux; ie you can run apt-get, etc. etc. 


Why Ubuntu 18.04
================

The latest version of Ubuntu supported currently (as of July 2022) by Hercules is Ubuntu 18.04. If you attempt to upgrade an existing Ubuntu 18.04 install to version 20.04 or higher, it will fail on IPL. 


After Installation
=================

You will have Ubuntu/s390x installed in dasd/hd0.120

You can remove all unnecessary files by executing

>sudo ./cleanup_after_successful_install.bash



Racingsmars/Moshix
July 2022
Milan
