################################################################################
#
# raspberrypi_omxcam
#
################################################################################

RASPBERRYPI_OMXCAM_VERSION = 8c5c086
RASPBERRYPI_OMXCAM_SITE = https://github.com/christianrauch/raspberrypi-omxcam.git
RASPBERRYPI_OMXCAM_SITE_METHOD = git
RASPBERRYPI_OMXCAM_INSTALL_STAGING := YES
RASPBERRYPI_OMXCAM_INSTALL_TARGET := YES

define RASPBERRYPI_OMXCAM_BUILD_CMDS
        $(MAKE) CC="$(TARGET_CC)" LD="$(TARGET_LD)" -C $(@D) all
endef

define RASPBERRYPI_OMXCAM_INSTALL_STAGING_CMDS
		mkdir -p $(STAGING_DIR)/usr/include
		$(INSTALL) -D -m 0644 $(@D)/include/* $(STAGING_DIR)/usr/include
endef

$(eval $(cmake-package))
