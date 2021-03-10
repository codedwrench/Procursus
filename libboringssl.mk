ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS    += libboringssl
LIBBORINGSSL_VERSION := 10.0.0+r36-1
DEB_LIBBORINGSSL_V   ?= $(LIBBORINGSSL_VERSION)

libboringssl-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://salsa.debian.org/android-tools-team/android-platform-external-boringssl/-/archive/debian/10.0.0+r36-1/android-platform-external-boringssl-debian-$(LIBBORINGSSL_VERSION).tar.gz
	$(call EXTRACT_TAR,android-platform-external-boringssl-debian-$(LIBBORINGSSL_VERSION).tar.gz,android-platform-external-boringssl-debian-$(LIBBORINGSSL_VERSION),libboringssl)
	$(call DO_PATCH,libboringssl,libboringssl,-p1)

ifneq ($(wildcard $(BUILD_WORK)/libboringssl/.build_complete),)
libboringssl:
	@echo "Using previously built libboringssl."
else
libboringssl: libboringssl-setup 
	cd $(BUILD_WORK)/libboringssl/src && mkdir -p build && cd build \
        	&& cmake .. -DCMAKE_OSX_SYSROOT=iphoneos -DCMAKE_OSX_ARCHITECTURES=$(MEMO_ARCH) \
	        -DOPENSSL_NO_ASM=1 -DBUILD_SHARED_LIBS=1 -DOPENSSL_SMALL=1
	+$(MAKE) -C $(BUILD_WORK)/libboringssl/src/build
	touch $(BUILD_WORK)/libboringssl/.build_complete
endif

libboringssl-package: libboringssl-stage
	# libboringssl.mk Package Structure
	rm -rf $(BUILD_DIST)/libboringssl
	mkdir -p $(BUILD_DIST)/libboringssl/usr/lib/boringssl
	
	# libboringssl.mk Prep libboringssl
	install_name_tool -id /usr/lib/boringssl/libcrypto.dylib $(BUILD_WORK)/libboringssl/src/build/crypto/libcrypto.dylib
	install_name_tool -id /usr/lib/boringssl/libssl.dylib $(BUILD_WORK)/libboringssl/src/build/ssl/libssl.dylib
	install_name_tool -change $(BUILD_WORK)/libboringssl/src/build/crypto/libcrypto.dylib /usr/lib/boringssl/libcrypto.dylib $(BUILD_WORK)/libboringssl/src/build/ssl/libssl.dylib

	# no `make install` target, so copy directly
	cp -a $(BUILD_WORK)/libboringssl/src/build/crypto/libcrypto.dylib $(BUILD_DIST)/libboringssl/usr/lib/boringssl
	cp -a $(BUILD_WORK)/libboringssl/src/build/ssl/libssl.dylib $(BUILD_DIST)/libboringssl/usr/lib/boringssl
	
	# libboringssl.mk Sign
	$(call SIGN,libboringssl,general.xml)
	
	# libboringssl.mk Make .debs
	$(call PACK,libboringssl,DEB_LIBBORINGSSL_V)
	
	# libboringssl.mk Build cleanup
	rm -rf $(BUILD_DIST)/libboringssl

.PHONY: libboringssl libboringssl-package
