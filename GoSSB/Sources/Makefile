# Copyright (C) 2019 Henry Bubert <cryptix@riseup.net>. All Rights Reserved.

IPHONEOS_DEPLOYMENT_TARGET ?= 13.0
MACOS_DEPLOYMENT_TARGET ?= 11.3


# architecture and SDK paths

CFLAGS := -Wno-unused-command-line-argument
# TODO customize above per platform

ARCHS_SIM = arm64 x86_64
PLATFORM_SIM = iPhoneSimulator
SDKROOT_SIM = $(shell xcode-select -print-path)/Platforms/$(PLATFORM_SIM).platform/Developer/SDKs/$(PLATFORM_SIM)$(IPHONEOS_SDK).sdk
EXTRA_CFLAGS_SIM += -pipe -fvisibility=hidden $(INCLUDE) -isysroot $(SDKROOT_SIM)
EXTRA_CFLAGS_SIM += -D__IPHONE_OS_VERSION_MIN_REQUIRED=20000 -miphonesimulator-version-min=$(IPHONEOS_DEPLOYMENT_TARGET)
CFLAGS_SIM = $(CFLAGS) $(EXTRA_CFLAGS_SIM)

ARCHS_PHONE = arm64
PLATFORM_PHONE = iPhoneOS
SDKROOT_PHONE = $(shell xcode-select -print-path)/Platforms/$(PLATFORM_PHONE).platform/Developer/SDKs/$(PLATFORM_PHONE)$(IPHONEOS_SDK).sdk
EXTRA_CFLAGS_PHONE += -pipe -fvisibility=hidden $(INCLUDE) -isysroot $(SDKROOT_PHONE)
EXTRA_CFLAGS_PHONE += -miphoneos-version-min=$(IPHONEOS_DEPLOYMENT_TARGET)
CFLAGS_PHONE = $(CFLAGS) $(EXTRA_CFLAGS_PHONE)

ARCHS_MAC = arm64 x86_64
PLATFORM_MAC = MacOSX
SDKROOT_MAC = $(shell xcode-select -print-path)/Platforms/$(PLATFORM_MAC).platform/Developer/SDKs/$(PLATFORM_MAC)$(MACOS_DEPLOYMENT_TARGET).sdk
EXTRA_CFLAGS_MAC += -pipe -fvisibility=hidden $(INCLUDE) -isysroot $(SDKROOT_MAC)
EXTRA_CFLAGS_MAC += -mmacosx-version-min=$(MACOS_DEPLOYMENT_TARGET)
CFLAGS_MAC = $(CFLAGS) $(EXTRA_CFLAGS_MAC)

CONFIGURATION_BUILD_DIR ?= $(CURDIR)/out
CONFIGURATION_TEMP_DIR ?= $(CURDIR)/.tmp

# compiler and linker
export CC ?= clang
LIPO ?= lipo
# path output
DESTDIR ?= $(CONFIGURATION_BUILD_DIR)
BUILDDIR ?= $(CONFIGURATION_TEMP_DIR)

# go architecture and platform settings
GOARCH_arm64 := arm64
GOARCH_x86_64 := amd64
GOARCHSIM_arm64 := arm64
GOARCHSIM_x86_64 := amd64
export GOOS_MAC := darwin
export GOOS_PHONE := ios
export GOOS_SIM_arm64 := ios
export GOOS_SIM_x86_64 := ios
export CGO_ENABLED := 1

# main build targets
build: $(BUILD_DIR)/$(PLATFORM_PHONE)-arm64/libssb-go.a $(BUILD_DIR)/$(PLATFORM_SIM)-arm64_x86_64/libssb-go.a $(BUILD_DIR)/$(PLATFORM_MAC)-arm64_x86_64/libssb-go.a

$(BUILD_DIR)/$(PLATFORM_SIM)-arm64_x86_64/libssb-go.a: $(foreach ARCH,$(ARCHS_SIM), $(BUILD_DIR)/$(PLATFORM_SIM)-$(ARCH)/libssb-go.a)
	@mkdir -vp $(BUILD_DIR)/$(PLATFORM_SIM)-arm64_x86_64
	$(LIPO) -create -output "$@" $^
	
$(BUILD_DIR)/$(PLATFORM_MAC)-arm64_x86_64/libssb-go.a: $(foreach ARCH,$(ARCHS_MAC), $(BUILD_DIR)/$(PLATFORM_MAC)-$(ARCH)/libssb-go.a)
	@mkdir -vp $(BUILD_DIR)/$(PLATFORM_MAC)-arm64_x86_64
	$(LIPO) -create -output "$@" $^


GOROOT ?= $(TEMP_ROOT)/.goroot
export GOPATH := $(BUILDDIR)/gopath
export PATH := $(GOROOT)/bin:$(PATH)

GO := $(GOROOT)/bin/go

GOEXTRAFLAGS=-trimpath -mod=vendor
GOBUILDTAGS = nommio x509omitbundledroots
# ifdef DEBUG <  this var is not set when the Build Step script is called  by Xcode
# ifeq ($(ENABLE_TESTABILITY),YES) < also works, not sure what the difference is
ifeq ($(CONFIGURATION),Debug)
    GOBUILDTAGS += testing
else
    GOEXTRAFLAGS += -ldflags="-s -w"
endif

# this builds multiple lib.a files for different ARCHS_PHONE
define libssb-go-phone-a
$(BUILD_DIR)/$(PLATFORM_PHONE)-$(1)/libssb-go.a: *.go
	CGO_CFLAGS="$(CFLAGS_PHONE) -arch $(ARCH)" \
	CGO_LDFLAGS="$(CFLAGS_PHONE) -arch $(ARCH)" \
	GOARCH="$(GOARCH_$(1))" \
	GOOS="$(GOOS_PHONE)" \
	${GO} build $(GOEXTRAFLAGS) -tags "$(GOBUILDTAGS) ios" -v -o "$(BUILD_DIR)/$(PLATFORM_PHONE)-$(1)/libssb-go.a" -buildmode c-archive && ${GO} version > "$(BUILDDIR)/.gobuildversion"; \
	ret=$$$$?; \
	rm -f "$(BUILDDIR)/libssb-go-phone-$(1).h"; \
	exit $$$$ret
endef
$(foreach ARCH,$(ARCHS_PHONE),$(eval $(call libssb-go-phone-a,$(ARCH))))

# build for sim with correct cflags
define libssb-go-sim-a
$(BUILD_DIR)/$(PLATFORM_SIM)-$(1)/libssb-go.a: *.go
	CGO_CFLAGS="$(CFLAGS_SIM) -arch $(ARCH)" \
	CGO_LDFLAGS="$(CFLAGS_SIM) -arch $(ARCH)" \
	GOARCH="$(GOARCHSIM_$(1))" \
	GOOS="$(GOOS_SIM_$(1))" \
	${GO} build $(GOEXTRAFLAGS) -tags "$(GOBUILDTAGS) iossimulator" -v -o "$(BUILD_DIR)/$(PLATFORM_SIM)-$(ARCH)/libssb-go.a" -buildmode c-archive && ${GO} version > "$(BUILDDIR)/.gobuildversion"
	ret=$$$$?; \
	rm -f "$(BUILDDIR)/libssb-go-sim-$(1).h"; \
	exit $$$$ret
endef
$(foreach ARCH,$(ARCHS_SIM),$(eval $(call libssb-go-sim-a,$(ARCH))))

# this builds multiple lib.a files for different ARCHS_MAC
define libssb-go-mac-a
$(BUILD_DIR)/$(PLATFORM_MAC)-$(1)/libssb-go.a: *.go
	CGO_CFLAGS="$(CFLAGS_MAC) -arch $(ARCH)" \
	CGO_LDFLAGS="$(CFLAGS_MAC) -arch $(ARCH)" \
	GOARCH="$(GOARCH_$(1))" \
	GOOS="$(GOOS_MAC)" \
	${GO} build $(GOEXTRAFLAGS) -tags "$(GOBUILDTAGS) ios" -v -o "$(BUILD_DIR)/$(PLATFORM_MAC)-$(1)/libssb-go.a" -buildmode c-archive && ${GO} version > "$(BUILDDIR)/.gobuildversion"; \
	ret=$$$$?; \
	exit $$$$ret
endef
$(foreach ARCH,$(ARCHS_MAC),$(eval $(call libssb-go-mac-a,$(ARCH))))

clean:
	rm -rf "$(BUILDDIR)" "$(DESTDIR)/libssb-go.a" 

install: build

.PHONY: clean build install
