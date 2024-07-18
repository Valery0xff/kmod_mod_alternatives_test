#!/bin/sh
# This script download kmod project, apply modules alternatives patches,
# build test kernel modules and running test cases to show modules alternatives
# functionality.
# Using modprobe to insert modules required sudo rigths so run this test
# under user with sudo rigths

#set -x

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


#Params:
#1 - KERNEL_HDR_DIR(kernel source/headers dir)
#2 - MOD_SRC_DIR(test modules source tree root dir)
#3 - MOD_INST_DIR - modules install dir
#4 - DIR(test module subdir into MOD_SRC_DIR)
build_install_single_mod() {
	local lKERNEL_HDR_DIR=$1
	local lMOD_SRC_DIR=$2
	local lMOD_INST_DIR=$3
	local lDIR=$4
	local lEXTRA_SYM_STR=""
	dep_file="$lMOD_SRC_DIR/$lDIR/depends.txt"
	if [ -f $dep_file ]; then
		deps=`cat $dep_file`
		for dep in $deps
		do
			build_install_single_mod $lKERNEL_HDR_DIR $lMOD_SRC_DIR $lMOD_INST_DIR $dep
			lEXTRA_SYM_STR="$lMOD_SRC_DIR/$dep/Module.symvers $lEXTRA_SYM_STR"
		done
	fi
	echo "Compiling module for: $lMOD_SRC_DIR/$lDIR"
	cur_pwd=`pwd`
	cd $lMOD_SRC_DIR/$lDIR
	make -C $lKERNEL_HDR_DIR M=$(pwd) KBUILD_EXTRA_SYMBOLS="$lEXTRA_SYM_STR"
	[ $? != 0 ] && die "Build module failed for: $lMOD_SRC_DIR/$lDIR"
	make -C $lKERNEL_HDR_DIR M=$(pwd) DEPMOD="echo" INSTALL_MOD_PATH="$lMOD_INST_DIR" INSTALL_MOD_DIR="extra" modules_install
	[ $? != 0 ] && die "Can't instal module from: $lMOD_SRC_DIR/$lDIR to $lMOD_INST_DIR"
	cd $cur_pwd
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

echo "Checking presence of required kmod utils..."
DEPMOD="$KMOD_INSTALL_DIR/usr/bin/depmod"
MODINFO="$KMOD_INSTALL_DIR/usr/bin/modinfo"
MODPROBE="$KMOD_INSTALL_DIR/usr/bin/modprobe"
RMMOD="$KMOD_INSTALL_DIR/usr/bin/rmmod"

[ ! -x $DEPMOD ] && die "Can't find depmod utility at: $DEPMOD"
[ ! -x $MODINFO ] && die "Can't find modinfo utility at: $MODINFO"
[ ! -x $MODPROBE ] && die "Can't find modprobe utility at: $MODPROBE"
[ ! -x $RMMOD ] && die "Can't find rmmod utility at: $RMMOD"
sleep 2

echo "Building kernel modules for testing"

if [ "x$KERNEL_HDR_DIR" = "x" ]; then
	KERNEL_HDR_DIR=`echo /usr/src/linux-headers-$(uname -r)`
fi
[ ! -d $KERNEL_HDR_DIR ] && die "Kernel headers die $KERNEL_HDR_DIR absent, please, setup proper value via KERNEL_HDR_DIR variable"

MOD_SRC_DIR="$KMOD_TEST_DIR/kmods_examples"
[ ! -d $MOD_SRC_DIR ] && die "Something wrong with test repo, can't find modules src dir: $KMOD_TEST_DIR"
cur_dir=`pwd`
cd $MOD_SRC_DIR
MOD_SRC_SUBDIRS=`ls -d */`
cd $cur_dir
[ "x$MOD_SRC_SUBDIRS" = "x" ] && die "Something wrong with test repo, can't find modules src subdirs in: $KMOD_TEST_DIR"

for dir in $MOD_SRC_SUBDIRS
do
	build_install_single_mod $KERNEL_HDR_DIR $MOD_SRC_DIR $KMOD_INSTALL_DIR $dir
done

echo "Build kernel modules examples finished"
sleep 2

echo "modules.buildin* indexes from main kernel required to load test modules"
echo "Copying modules.buildin* from current kernel to test module dir"
cp -f /lib/modules/$(uname -r)/modules.builtin* $KMOD_INSTALL_DIR/lib/modules/$(uname -r)/
echo "Generating modules db indexes for test modules via baseline algorithm"
MODDB_STD_DIR="$KMOD_INSTALL_DIR/moddb_std"
CMD="$DEPMOD -b $KMOD_INSTALL_DIR -o $MODDB_STD_DIR"
$CMD
[ $? != 0 ] && die "Can't generate modules db index via cmd: $CMD"
echo "Modules db indexes stored to: $MODDB_STD_DIR"

echo "Generating modules db indexes for test modules with alternatives algorithm"
MODDB_ALT_DIR="$KMOD_INSTALL_DIR/moddb_alt"
CMD="$DEPMOD -D -b $KMOD_INSTALL_DIR -o $MODDB_ALT_DIR"
$CMD
[ $? != 0 ] && die "Can't generate modules db index via cmd: $CMD"
echo "Modules db indexes stored to: $MODDB_ALT_DIR"

MOD_DEPS_STD_F=`find $MODDB_STD_DIR -name "modules.dep"`
[ "x$MOD_DEPS_STD_F" = "x" ] && die "Can't find modules.dep file in $MODDB_STD_DIR"

MOD_DEPS_ALT_F=`find $MODDB_ALT_DIR -name "modules.dep"`
[ "x$MOD_DEPS_ALT_F" = "x" ] && die "Can't find modules.dep file in $MODDB_ALT_DIR"

echo ""
echo "Modules dependencies with baseline algo:"
cat $MOD_DEPS_STD_F
echo "#------------------------#"
echo ""
echo "Modules dependencies with alternatives algo:"
cat $MOD_DEPS_ALT_F
echo "#------------------------#"


exit 0

