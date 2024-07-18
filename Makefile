
mkfile_path := $(abspath $(lastword $(MAKEFILE_LIST)))
mkfile_dir := $(dir $(mkfile_path))

all:
	$(mkfile_dir)kmod_mod_alt_test.sh

clean:
	rm -fR $(mkfile_dir)kmod.src
	rm -fR $(mkfile_dir)kmod_inst
	make -C $(mkfile_dir)kmods_examples cleanall
