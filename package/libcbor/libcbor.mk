LIBCBOR_VERSION := v0.5.0
LIBCBOR_SITE := https://github.com/PJK/libcbor
LIBCBOR_SITE_METHOD := git
LIBCBOR_INSTALL_STAGING := YES
LIBCBOR_INSTALL_TARGET := YES

$(eval $(cmake-package))
