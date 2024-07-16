#!/bin/sh
# This script download kmod project, apply modules alternatives patches,
# build test kernel modules and running test cases to show modules alternatives
# functionality.
# Using modprobe to insert modules required sudo rigths so run this test
# under user with sudo rigths

set -x

KMOD_GIT_URL="https://github.com/kmod-project/kmod.git"
KMOD_COMMIT="fa715f8c8b78a09f47701ce1cf46e9b67a49b8d0" #base kmod commit
KMOD_PATCHES=" \
0001-tools-depmod.c-use-symbol-alternatives-for-modules.d.patch \
0002-kmod-add-generation-of-modules.alternatives-to-depmo.patch \
0003-kmod-add-modules.alternatives-to-modprobe.patch \
0004-add-modules-deps-alternatives-description.patch \
"

die() {
	echo "$1"
	exit 1
}

git --help &>/dev/null || die "Can't run git, please install git via your pkg manager"

script_path=`readlink -f $0`
export KMOD_TEST_DIR=`dirname $script_path`
[ ! -d $KMOD_TEST_DIR ] && die "Can't detect script directory"
export KMOD_INSTALL_DIR=$KMOD_TEST_DIR/kmod_inst

CUR_DIR=`pwd`
[ "x$CUR_DIR" = "x" ] && die "Can't detect current directory"

for patch in $KMOD_PATCHES
do
	[ ! -f $KMOD_TEST_DIR/patches.kmod/$patch ] && die "Can't find patch: $patch into dir: $KMOD_TEST_DIR/patches.kmod"
done

echo "Preparing kmod sources..."
cd $KMOD_TEST_DIR
[ -d $KMOD_TEST_DIR/kmod.src ] && rm -fr $KMOD_TEST_DIR/kmod.src 
git clone $KMOD_GIT_URL kmod.src
[ "x$?" != "x0" ] && die "Can't clone kmod repo from $KMOD_GIT_URL"
cd kmod.src
git checkout -b mod_alt $KMOD_COMMIT
[ "x$?" != "x0" ] && die "Can't switch kmod to commit: $KMOD_COMMIT"

for patch in $KMOD_PATCHES
do
	git am -3 $KMOD_TEST_DIR/patches.kmod/$patch
	[ "x$?" != "x0" ] && die "Can't apply kmod patch: $patch"
done

echo "Building kmod..."
./autogen.sh
[ "x$?" != "x0" ] && die "kmod autogen.sh exit with error, check kmod docs to solve problem"

./configure CFLAGS='-g -O2' --prefix=/usr --sysconfdir=/etc --libdir=/usr/lib --with-rootlibdir=/lib --disable-manpages
[ "x$?" != "x0" ] && die "kmod configure failed, check kmod docs to solve the problem"

make
[ "x$?" != "x0" ] && die "kmod build failed, check build logs and kmod docs to solve the problem"

make DESTDIR=$KMOD_INSTALL_DIR install
[ "x$?" != "x0" ] && die "kmod install to $KMOD_INSTALL_DIR failed, check install logs and kmod docs to solve the problem"

echo "Building kmod with modules alternatives feature finished, utilities installed into $KMOD_INSTALL_DIR"
exit 0

