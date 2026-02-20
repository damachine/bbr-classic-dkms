# Maintainer: damachin3 (damachine3 at proton dot me)
# Website: https://github.com/damachine/bbr_classic-multi
modname        := tcp_bbr_classic
src_in         := tcp_bbr.c
BUILD_DIR      ?= build
BUILD_DIR_ABS  := $(abspath $(BUILD_DIR))
src_out        := $(BUILD_DIR_ABS)/tcp_bbr_classic.c
KBUILD_FILE    := $(BUILD_DIR_ABS)/Kbuild

KVERSION       ?= $(shell uname -r)
KDIR           := /lib/modules/$(KVERSION)/build
MODVER         ?= $(shell echo $(KVERSION) | cut -d. -f1-2)
DKMS           ?= dkms
DKMS_MODNAME   ?= bbr-classic
DKMS_DEST      ?= /usr/src/$(DKMS_MODNAME)-$(MODVER)
KCONFIG        := /lib/modules/$(KVERSION)/build/.config
KERNEL_CC      := $(shell grep -qs '^CONFIG_CC_IS_CLANG=y' $(KCONFIG) && echo clang)
SRC_URL        := https://raw.githubusercontent.com/torvalds/linux/v$(MODVER)/net/ipv4/tcp_bbr.c

ifeq ($(KERNEL_CC),clang)
    LLVM_FLAGS := LLVM=1
endif

Q = @
KECHO = printf "  %-8s%s\n"

.ONESHELL:

default: $(src_out)
	$(Q)$(MAKE) -C $(KDIR) M=$(BUILD_DIR_ABS) $(LLVM_FLAGS) modules

$(BUILD_DIR_ABS):
	$(Q)mkdir -p $(BUILD_DIR_ABS)

$(KBUILD_FILE): | $(BUILD_DIR_ABS)
	$(Q)printf 'obj-m := $(modname).o\n' > $(KBUILD_FILE)

$(src_in):
	$(Q)$(KECHO) "FETCH" "$(src_in)"
	$(Q)curl -sL -o $(src_in) "$(SRC_URL)"

$(src_out): $(src_in) $(KBUILD_FILE)
	$(Q)$(KECHO) "PATCH" "$(src_out)"
	$(Q)cp $(src_in) $(src_out)
	$(Q)sed -i 's/"bbr"/"bbr_classic"/g' $(src_out)
	$(Q)sed -i 's/struct bbr/struct bbr_classic/g' $(src_out)
	$(Q)sed -i 's/ret = register_btf_kfunc_id_set.*/ret = 0; \/\/ skip BTF kfunc registration (out-of-tree)/' $(src_out)
	$(Q)header_file=""
	for candidate in "$(KDIR)/source/include/net/tcp.h" "$(KDIR)/include/net/tcp.h"; do
		if [ -f "$$candidate" ]; then
			header_file="$$candidate"
			break
		fi
	done
	if [ -z "$$header_file" ]; then
		$(KECHO) "WARN" "tcp.h not found, skipping min_tso_segs check" >&2
	elif ! grep -q "min_tso_segs" "$$header_file"; then
		sed -i 's/\.min_tso_segs/\/\/ .min_tso_segs/g' $(src_out)
	fi

clean:
	$(Q)if [ -d "$(BUILD_DIR_ABS)" ]; then
		$(MAKE) -C $(KDIR) M=$(BUILD_DIR_ABS) $(LLVM_FLAGS) clean
	fi
	$(Q)$(KECHO) "CLEAN" "$(BUILD_DIR_ABS)"
	$(Q)rm -rf $(BUILD_DIR_ABS)
	$(Q)rm -f $(src_in)
	$(Q)rm -f *.zst *.pkg.tar.*
	$(Q)rm -rf pkg/ src/

load:
	$(Q)$(KECHO) "RMMOD" "$(modname)"
	$(Q)-rmmod $(modname)
	$(Q)$(KECHO) "INSMOD" "$(modname).ko"
	$(Q)insmod $(BUILD_DIR_ABS)/$(modname).ko

install:
	$(Q)if [ ! -f "$(BUILD_DIR_ABS)/$(modname).ko" ]; then
		printf "  ERROR   Module not built. Run 'make' first.\n" >&2; exit 1
	fi
	$(Q)$(KECHO) "INSTALL" "/lib/modules/$(KVERSION)/kernel/net/ipv4/$(modname).ko"
	$(Q)install -Dm644 $(BUILD_DIR_ABS)/$(modname).ko \
		/lib/modules/$(KVERSION)/kernel/net/ipv4/$(modname).ko
	$(Q)$(KECHO) "DEPMOD" "$(KVERSION)"
	$(Q)depmod -a $(KVERSION)

uninstall:
	$(Q)$(KECHO) "REMOVE" "/lib/modules/$(KVERSION)/kernel/net/ipv4/$(modname).ko"
	$(Q)rm -f /lib/modules/$(KVERSION)/kernel/net/ipv4/$(modname).ko
	$(Q)$(KECHO) "DEPMOD" "$(KVERSION)"
	$(Q)depmod -a $(KVERSION)

help:
	@echo "Available targets:"
	@printf "  %-30s - %s\n" "make"                   "Download tcp_bbr.c and build the module"
	@printf "  %-30s - %s\n" "make KVERSION=6.18.13"  "Build for a specific kernel"
	@printf "  %-30s - %s\n" "make clean"             "Remove build directory and downloaded tcp_bbr.c"
	@printf "  %-30s - %s\n" "sudo make load"         "Load module for testing (insmod)"
	@printf "  %-30s - %s\n" "sudo make install"      "Install module permanently (no DKMS)"
	@printf "  %-30s - %s\n" "sudo make uninstall"    "Remove permanently installed module"
	@printf "  %-30s - %s\n" "sudo make dkms-install" "Install via DKMS (auto-rebuild on kernel update)"
	@printf "  %-30s - %s\n" "sudo make dkms-uninstall" "Remove DKMS installation"

dkms-src-install: $(src_in)
	$(Q)$(KECHO) "DKMS" "copying sources to $(DKMS_DEST)"
	$(Q)mkdir -p '$(DKMS_DEST)'
	$(Q)cp Makefile tcp_bbr.c '$(DKMS_DEST)'
	$(Q)sed 's/@VERSION@/$(MODVER)/' dkms.conf > '$(DKMS_DEST)/dkms.conf'

dkms-build: dkms-src-install
	$(Q)$(KECHO) "DKMS" "building $(DKMS_MODNAME)-$(MODVER)"
	$(Q)$(DKMS) build -m $(DKMS_MODNAME) -v $(MODVER)

dkms-install: dkms-build
	$(Q)$(KECHO) "DKMS" "installing $(DKMS_MODNAME)-$(MODVER)"
	$(Q)$(DKMS) install -m $(DKMS_MODNAME) -v $(MODVER)

dkms-uninstall:
	$(Q)$(KECHO) "DKMS" "removing $(DKMS_MODNAME)-$(MODVER)"
	$(Q)$(DKMS) remove -m $(DKMS_MODNAME) -v $(MODVER) --all
	$(Q)rm -rf '$(DKMS_DEST)'

.PHONY: default clean help load install uninstall \
        dkms-src-install dkms-build dkms-install dkms-uninstall
