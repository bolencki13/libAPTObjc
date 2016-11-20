GO_EASY_ON_ME = 1
SDKVERSION = 9.2

include $(THEOS)/makefiles/common.mk

LIBRARY_NAME = libAptObjc
libAptObjc_FILES = AptObjc.mm $(wildcard *.m) BZipCompression/BZipCompression.m
libAptObjc_CFLAGS = -fobjc-arc
libAptObjc_LIBRARIES = bz2

include $(THEOS_MAKE_PATH)/library.mk
