SHELL := /bin/bash

export CURDIR
export PLATFORM ?= $(shell cat $(CURDIR)/build/.platform)
BASE_DIR := $(CURDIR)/build/output-$(PLATFORM)
TARGET_DIR := $(BASE_DIR)/target
export BOARD_DIR := $(CURDIR)/configs/$(PLATFORM)
export BR2_EXTERNAL := $(CURDIR)

DEV ?= rpi0

include $(BOARD_DIR)/defconfig
LINUX_DIR := $(BASE_DIR)/build/linux-$(BR2_LINUX_KERNEL_CUSTOM_REPO_VERSION)

################################################################################
# Buildroot
################################################################################

.PHONY: default
default: all
all menuconfig toolchain: $(BASE_DIR)/.config

$(BASE_DIR)/.config:
	$(MAKE) prep

.PHONY: prep
prep: patch config-rpi0
	$(MAKE) defconfig

## Apply custom patches to Buildroot
.PHONY: patch
patch:
	@ for file in patches/*; do \
		if ! patch -d buildroot -Rf --dry-run --silent -p1 < $$file > /dev/null; then \
			patch -d buildroot -p1 < $$file; \
		fi \
	done

## Initial setup for specific platform
.PHONY: config-%
config-%:
	mkdir -p build
	echo $* > $(CURDIR)/build/.platform

## Pass Makefile targets not defined here to buildroot
%:
	$(MAKE) O=$(BASE_DIR) BR2_DEFCONFIG=$(BOARD_DIR)/defconfig -C buildroot $*

.PHONY: clean-target
clean-target:
	rm -rf $(TARGET_DIR)
	find $(BASE_DIR)/ -name ".stamp_target_installed" |xargs rm -rf

.PHONY: diffconfig
diffconfig:
	$(LINUX_DIR)/scripts/diffconfig -m $(LINUX_DIR)/arch/arm/configs/bcmrpi_defconfig $(BOARD_DIR)/defconfig

################################################################################
# Deployment
################################################################################

## Flash built image to SD card, e.g., make flash-sdx.
.PHONY: flash-%
flash-%:
	@mkdir -p $(CURDIR)/build/mnt
	@sudo umount $(CURDIR)/build/mnt || true
	@sudo umount /dev/$*?* || true
	@sudo dd if=$(BASE_DIR)/images/sdcard.img of=/dev/$* bs=4k
	@sync
	@sudo configs/expand-rootfs.sh /dev/$* || true
	@sudo e2fsck -f /dev/$*2 || true
	@sudo resize2fs /dev/$*2
	@sudo mount /dev/$*2 $(CURDIR)/build/mnt
	@sudo mount /dev/$*1 $(CURDIR)/build/mnt/boot
	@sudo dd if=/dev/zero of=$(CURDIR)/build/mnt/opt/vfat.img count=32 bs=1M
	@sudo mkfs.vfat $(CURDIR)/build/mnt/opt/vfat.img
	@sudo fatlabel $(CURDIR)/build/mnt/opt/vfat.img $$(echo $(DEV) | tr [a-z] [A-Z])
	@sync
	@sudo umount /dev/$*?*

SSH_KEY = configs/$(PLATFORM)/rootfs/root/.ssh/id_rsa

.PHONY: upload
upload:
	rsync -avzz -e "ssh -i $(SSH_KEY)" --chown=root:root $(TARGET_DIR)/{etc,lib,bin,usr,root,srv}  root@$(DEV).local:/

.PHONY: sys-upload
sys-upload:
	rsync -avzz -e "ssh -i $(SSH_KEY)" --chown=root:root --inplace $(BASE_DIR)/images/{MLO,u-boot.img,*.dtb,*.txt,zImage,bzImage}  root@$(DEV).local:/boot/
