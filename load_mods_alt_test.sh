#!/bin/sh
#Params:
#1 - path to report/output file
#2 - path to modprobe
#3 - path to rmmod
#4 - path to lsmod
#5 - path to modules db indexes

#set -x

die() {
	echo "$1"
	exit 1
}

#echo string to output and file
#Params:
#1 - string
#2 - filename
echo_dup() {
	printf "$1\n"
	printf "$1\n" >>$2
}

#load module via modprobe and store output to report
#Params:
#1 - module name
#2 - modules db path(where depmod generated indexes)
#3 - path to modprobe
#4 - path to lsmod
#5 - output report filename
mod_load() {
	local lMOD=$1
	local lMODDB=$2
	local lMPROBE=$3
	local lLSMOD=$4
	local lREPORT=$5
	echo_dup "#----#" $lREPORT
	out=`$lLSMOD | grep -e '^mod_.*api' -e '^Module.*Size'`
	echo_dup "Modules before load $lMOD:" $lREPORT
	echo_dup "$out" $lREPORT
	echo_dup "#----#"  $lREPORT

	echo_dup "Loading module: $lMOD" $lREPORT
	echo_dup "CMD: $lMPROBE -d $lMODDB $lMOD" $lREPORT
	$lMPROBE -d $lMODDB $lMOD
	[ "x$?" = "x0" ] && echo_dup "Loading module: $lMOD success" $lREPORT || echo_dup "Loading module: $lMOD failed" $lREPORT

	out=`journalctl -kS -8sec | grep "$lMOD"`
	echo_dup "Logs from $lMOD module:" $lREPORT
	echo_dup "$out" $lREPORT
	echo_dup "#----#"  $lREPORT

	out=`$lLSMOD | grep -e '^mod_.*api' -e '^Module.*Size'`
	echo_dup "Modules after load $lMOD:" $lREPORT
	echo_dup "$out" $lREPORT
	echo_dup "#----#"  $lREPORT
}

#remove all mod_*api modules
#Params:
#1 - path to rmmod util
#2 - path to lsmod util
mod_rmall_api() {
	local lRMMOD="$1"
	local lLSMOD="$2"
	#depended modules alphabetically later in this test repo so use "sort -r"
	#for proper rmmod order
	mods_for_rm=`$lLSMOD | grep -e "^mod_.*api" | awk '{print $1}' | sort -r`
	for mod in $mods_for_rm
	do
		$lRMMOD $mod
		[ "x$?" != "x0" ] && die "Can't rmmod: $mod"
	done
}


[ "$#" -ne 5 ] && die "Parameters count invalid, stopped"

REPORT="$1"
MODPROBE="$2"
RMMOD="$3"
LSMOD="$4"
MODDB_DIR="$5"

[ ! -x $MODPROBE ] && die "modprobe at: $MODPROBE is not executable"
[ ! -x $RMMOD ] && die "rmmod at: $RMMOD is not executable"
[ ! -x $MODINFO ] && die "modinfo at: $MODINFO is not executable"
[ ! -d $MODDB_DIR ] && die "modules db dir absent"

rm -f $REPORT
echo_dup "Loading modules with default api providers" $REPORT
echo_dup "#--------------------------------#" $REPORT
echo_dup "Loading modules with default deps" $REPORT
mod_load "mod_g_dapi1" $MODDB_DIR $MODPROBE $LSMOD $REPORT
mod_rmall_api $RMMOD $LSMOD
mod_load "mod_h_dapi1" $MODDB_DIR $MODPROBE $LSMOD $REPORT
mod_rmall_api $RMMOD $LSMOD
mod_load "mod_j_dapi12" $MODDB_DIR $MODPROBE $LSMOD $REPORT
mod_rmall_api $RMMOD $LSMOD
mod_load "mod_k_dapi123" $MODDB_DIR $MODPROBE $LSMOD $REPORT
mod_rmall_api $RMMOD $LSMOD
mod_load "mod_l_dapi1234" $MODDB_DIR $MODPROBE $LSMOD $REPORT
mod_rmall_api $RMMOD $LSMOD
sleep 10
echo_dup "#--------------------------------#" $REPORT
echo_dup "Loading modules with specific deps" $REPORT
mod_load "mod_e_api123" $MODDB_DIR $MODPROBE $LSMOD $REPORT
mod_load "mod_g_dapi1" $MODDB_DIR $MODPROBE $LSMOD $REPORT
mod_load "mod_h_dapi1" $MODDB_DIR $MODPROBE $LSMOD $REPORT
mod_rmall_api $RMMOD $LSMOD
mod_load "mod_b_api1" $MODDB_DIR $MODPROBE $LSMOD $REPORT
mod_load "mod_f_api2" $MODDB_DIR $MODPROBE $LSMOD $REPORT
mod_load "mod_j_dapi12" $MODDB_DIR $MODPROBE $LSMOD $REPORT
mod_rmall_api $RMMOD $LSMOD
sleep 10
echo_dup "#--------------------------------#" $REPORT
echo_dup "Loading one api provider instead of two separate" $REPORT
mod_load "mod_e_api123" $MODDB_DIR $MODPROBE $LSMOD $REPORT
mod_load "mod_j_dapi12" $MODDB_DIR $MODPROBE $LSMOD $REPORT
mod_rmall_api $RMMOD $LSMOD
echo_dup "#--------------------------------#" $REPORT
exit 0
