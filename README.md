## kmod with modules alternatives featute examples/tests repo

OVERVIEW
========

kmod modules alternatives is feature that allow to use different external modules
with the same exported symbols(api's). It change kmod dependency logic
significantly so proposed as alternative kmod algorithm instead of patching
mainline one. To use "modules altenatives" feature it required add "-D" flag to
depmod during generation modules indexes. It create additional index
"modules.alternatives"/ "modules.alternatives.bin" into modules db
directrory(output directory)

This repository contain:

a) Patches to kmod project required for implement "modules alternatives"
feature

b) Set of simple kernel modules "Hello" like style but with exported symbols to
demonstrate "modules alternatives" algorithm

c) Scripts to download/compile patched kmod, build test modules and produce
reports

d) Generated reports(deps_report.txt, load_mods_report.txt) from my build to
compare results

Comparision of dependencies differences generated via "mainline" and
"alternatives" algorithms stored into deps_report.txt
Loading modules result with different api providers/load variants stored to
load_mods_report.txt

Most important field into deps_report.txt is "desp stat", allowed field value:
1. equal - means that build deps equal to kmod deps
2. different - means that build deps and kmod deps different but module can be
loaded by modprobe/insmod
3. conflict - means that kmod generated invalid deps and module can't be loadable
via modprobe/insmod

Most important output into load_mods_report.txt is logs from kernel modules
It show what data(api) provider used during loading depended modules, test
modules using "pr_info" function to print logs so if logs absent into report,
first at all check kernel log level, then presence of "journalctl" utility, it
used for extracting test modules logs

Test modules name format/convention is:

mod_[letters]_api[NUMBERS].ko

mod_[letters]_dapi[NUMBERS].ko

Where letters set of a..z and doesn't important and numbers is set of 1..9 and
inform about providing/using specific api function, "api" - is api provider,
"dapi" - module depend on api

Examples:

mod_a_api1.c - export function mod_api1_func

mod_fc_api34.c - export mod_api3_func, mod_api4_func

mod_j_dapi12.c - require functions mod_api1_func and mod_api2_func


Compilation and report generation
=================================

To generate reports run next cmd after downloading repo:
make clean && make

To be success, compilation required all deps that needed for build kmod project
and linux kernel modules

See kmod project page and kernel build system docs:
https://github.com/kmod-project/kmod
https://docs.kernel.org/kbuild/modules.html

It also required:

a) installation of "git" on your system to do downloading kmod sources and
apply "modules alternatives" patches

b) "systemd" based linux system(scripts using journalctl util to parse kernel
modules output)

c) having at least "info" level of kernel logs(test mods use "pr_info" function
for output logs)

d) modules.buildtin* indexes into /lib/modules/$(uname -r) from current kernel

full compilation steps on clean ubuntu 24.04:
1. sudo apt install build-essential git autotools-dev autoconf pkgconf libtool
2. git config --global user.email "you@example.com"
3. git config --global user.name "Your Name"
4. git clone https://github.com/Valery0xff/kmod_mod_alternatives_test.git kmod_modules_alteratives
5. cd kmod_modules_alteratives
6. make clean && make

If build requirements already installed/configured run from step 4.
After build finished new reports deps_report.txt, load_mods_report.txt will be
generated.
Load/Unload kernel modules is privilege operation so it require "sudo" rigths.
It will be asked before running load_mods_alt_test.sh script

