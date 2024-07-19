
mkfile_path := $(abspath $(lastword $(MAKEFILE_LIST)))
mkfile_dir := $(dir $(mkfile_path))

all:
	$(mkfile_dir)kmod_mod_alt_test.sh

clean:
	rm -fR $(mkfile_dir)kmod.src
	rm -fR $(mkfile_dir)kmod_inst
	rm -f $(mkfile_dir)deps_report.txt
	rm -f $(mkfile_dir)load_mods_report.txt
	make -C $(mkfile_dir)kmods_examples cleanall
