
SUBDIRS := $(wildcard */.)
$(info $(SUBDIRS))

all:
	@echo "This makefile only for clean all modules in subdirs"
	@echo "Usage:"
	@echo "make cleanall"

$(SUBDIRS):
	@echo "subdir $@"
	$(MAKE) -C $@ clean

cleanall: $(SUBDIRS)
	@echo "cleanall finished"

.PHONY: cleanall $(SUBDIRS)
