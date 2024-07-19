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

#echo string to output and file
#Params:
#$1 - string
#$2 - filename
echo_dup() {
	echo $1
	echo $1 >>$2
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


#Params:
#1 - module name(like mod.ko)
#2 - modules location dir(like KMOD_INST_DIR/lib/modules)
#3 - modules.dep file
#4 - modinfo utility path
#5 - output report file
check_mod_deps() {
	local lMOD=$1
	local lMOD_DIR=$2
	local lMOD_DEP_F=$3
	local lMODINFO=$4
	local lOUT_F=$5
	mod_f_path=`find $lMOD_DIR -name $lMOD`
	[ "x$mod_f_path" = "x" ] && die "check_mod_deps: Can't find module path for $lMOD"
	minfo_deps=`$lMODINFO -Fdepends $mod_f_path`
	#modinfo deps is comma separated, rework list to something that correspond modules.dep format
	build_deps=""
	OIFS=$IFS
	IFS=","
	for dep in $minfo_deps
	do
		#all external modules, by default, placed to extra dir by kernel build system
		build_deps="extra/$dep.ko $build_deps"
	done
	IFS=$OIFS
	#echo "mod: $lMOD, build deps: $build_deps"
	mod_deps=`cat $lMOD_DEP_F | grep -e "^extra/$lMOD:" | awk -F": " '{print $2}'`

	#exclude each deps of one type from another to make comparithion
	mod_deps_cp=$mod_deps
	for dep in $build_deps
	do
		out_s=`echo $mod_deps_cp | sed 's|'$dep'||g'`
		mod_deps_cp=$out_s
	done
	build_deps_cp=$build_deps
	for dep in $mod_deps
	do
		out_s=`echo $build_deps_cp | sed 's|'$dep'||g'`
		build_deps_cp=$out_s
	done

	#calculate dependencies status
	diff_s="$build_deps_cp $mod_deps_cp"
	diff_cnt=`echo $diff_s | awk '{print NF}'`
	if [ "x$diff_cnt" != "x0" ]; then
		DEP_STAT="different"
		#check is generated deps loadable(functions/api overlapping)
		API_LIST=""
		API_CONFLICT=""
		for dep in $mod_deps
		do
			dep_api_str=`echo "$dep" | sed 's/.*api*//g' | sed 's/\.ko$//g' | awk -v FS="" '{for (i=1;i<=NF;i++) printf $i" "}'`
			for api in $dep_api_str
			do
				is_api_in_list=`echo $API_LIST | grep $api`
				if [ "x$is_api_in_list" != "x" ]; then
					API_CONFLICT="1"
					break
				else
					API_LIST="$api $API_LIST"
				fi
			done
			if [ "x$API_CONFLICT" != "x" ]; then
				DEP_STAT="\e[0;31mconflict\e[0m"
				break
			fi
		done
	else
		DEP_STAT="equal"
	fi
	mod_deps_out=$mod_deps
	if [ "x$mod_deps_out" = "x" ]; then
		mod_deps_out="\t"
	fi
	echo_dup "$lMOD\t$DEP_STAT\t$mod_deps_out\t$mod_f_path" $lOUT_F
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
LSMOD="$KMOD_INSTALL_DIR/usr/bin/lsmod"

[ ! -x $DEPMOD ] && die "Can't find depmod utility at: $DEPMOD"
[ ! -x $MODINFO ] && die "Can't find modinfo utility at: $MODINFO"
[ ! -x $MODPROBE ] && die "Can't find modprobe utility at: $MODPROBE"
[ ! -x $RMMOD ] && die "Can't find rmmod utility at: $RMMOD"
[ ! -x $LSMOD ] && die "Can't find lsmod utility at: $LSMOD"
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


echo "Checking moddb dependencies to corresponding buildtime dependencies"
echo "Using generated deps from modules.dep file and build deps from modinfo util"
echo ""

MOD_LIST=`find $KMOD_INSTALL_DIR/lib/modules -name "*.ko" | awk -F/ '{print $NF}'`
[ "x$MOD_LIST" = "x" ] && die "Can't find any module in $KMOD_INSTALL_DIR/lib/modules"

#echo "MOD_LIST: $MOD_LIST"

DEP_REPORT_F="$KMOD_TEST_DIR/deps_report.txt"
rm -f $DEP_REPORT_F
echo "" >$DEP_REPORT_F
echo_dup "Comparing modules deps for baseline algo" $DEP_REPORT_F
echo_dup "mod:\tdesp stat:\tmodules.dep deps:\tmod path:" $DEP_REPORT_F
for mod in $MOD_LIST
do
	check_mod_deps $mod $KMOD_INSTALL_DIR/lib/modules $MOD_DEPS_STD_F $MODINFO $DEP_REPORT_F
done
echo_dup "#------------------------#" $DEP_REPORT_F
echo_dup "" $DEP_REPORT_F
echo_dup "Comparing modules deps for alternatives algo" $DEP_REPORT_F
echo_dup "mod:\tdesp stat:\tmodules.dep deps:\tmod path:" $DEP_REPORT_F
for mod in $MOD_LIST
do
	check_mod_deps $mod $KMOD_INSTALL_DIR/lib/modules $MOD_DEPS_ALT_F $MODINFO $DEP_REPORT_F
done
echo_dup "#------------------------#" $DEP_REPORT_F
echo ""
echo "Now demonstrate modules alternatives feature with loading default and alternatives api provides"

echo "Copy mods from $KMOD_INSTALL_DIR/lib/modules to mods alternatives index dir $MODDB_ALT_DIR"
cp -fr $KMOD_INSTALL_DIR/lib/modules/* $MODDB_ALT_DIR/lib/modules/
[ "x$?" != "x0" ] && die "Can't copy modules to $MODDB_ALT_DIR"

echo "Loading and removing modules require root privilege"
echo "Current user should be part of sudoers"
echo "test script use next cmd for removing test modules: lsmod | grep -e \"^mod_.*api\""
echo "Please, check is some already loaded modules into your system correspond to this filter!"
echo "Don't run modules load test if some real module used!"
echo "Press enter to continue"
read varname

LOAD_MODS_REPORT_F="$KMOD_TEST_DIR/load_mods_report.txt"
echo "cmd: load_mods_alt_test.sh $LOAD_MODS_REPORT_F $MODPROBE $RMMOD $LSMOD $MODDB_TST_DIR"
sudo $KMOD_TEST_DIR/load_mods_alt_test.sh $LOAD_MODS_REPORT_F $MODPROBE $RMMOD $LSMOD $MODDB_ALT_DIR

echo "Reporst stored to:"
echo "Dependencies: $DEP_REPORT_F"
echo "Loading modules: $LOAD_MODS_REPORT_F"
exit 0

