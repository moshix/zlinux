#!/bin/sh

set -ue

# THIS SCRIPT IS INCLUDED FOR REFERENCE AND DISTRIBUTION MAINTENANCE.
# THERE IS NO EXPECTATION ZLINUX/ZUBUNTU TURNKEY USERS WILL RUN IT.

# This script builds the latest SDL-Hyperion from git. The goal is to build a
# "relocatable" set of binaries and libraries so that we can distribute this in
# the turnkey zUbuntu system.
#
# To do this, we will make sure the build artifacts have a rpath set to a
# relative directory location, namely ./herc4x/lib. This will ensure that if
# you run the "hercules" command from a directory that has the ./herc4x/lib
# subdirectory, the dynamic linker will find the Hercules libraries.
#
# There is a key advantage to doing this over setting LD_LIBRARY_PATH at
# runtime: the hercifc binary will need to be setuid root, but setuid binaries
# ignore LD_LIBRARY_PATH. That won't work for our purposes, so we need ld.so to
# find the necessary libraries without any environment overrides.

# For the zlinux turnkey distribution, we run this script on Debian 9, an old
# enough distribution that the libc we link against should be compatible with a
# wide range of Linux distributions.

### IMPORTANT: this is really just a one-time script to run in a clean
### Debian build server. If you run multiple times on the same system,
### you're responsible for cleaning up before running it again.

SUDO="sudo"

$SUDO apt-get update -y
$SUDO apt-get install -y zlib1g-dev build-essential git \
	libltdl-dev libbz2-dev

git clone https://github.com/SDL-Hercules-390/hyperion.git \
	sdl-hyperion-git
mkdir sdl-hyperion-build
cd sdl-hyperion-build
../sdl-hyperion-git/configure --prefix=/tmp/herc4x \
	CFLAGS="-m64 -march=x86-64 -mtune=generic -O1" \
	LDFLAGS="-Wl,-rpath=./herc4x/lib,-rpath=./herc4x/lib/hercules" \
	LT_SYS_LIBRARY_PATH=./herc4x/lib:./herc4x/lib/hercules
make -j 2
make install
cd ..

# Include the Hercules copyright notice in the distributed binary release.
cp sdl-hyperion-git/COPYRIGHT /tmp/herc4x

tar -c -f herc4x.tgz -z -C /tmp herc4x

echo "*** herc4x distribution ready in herc4x.tgz"

