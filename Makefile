TARGET := iphone:clang:latest:13.0
INSTALL_TARGET_PROCESSES = Instagram

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = UnifiedTweak

UnifiedTweak_FILES = \
	AT10Injector.m \
	AT10OverlayView.m \
	AT10OverlayWindow.m

UnifiedTweak_CFLAGS = -fobjc-arc

UnifiedTweak_FRAMEWORKS = \
	UIKit \
	Foundation \
	QuartzCore \
	CoreGraphics

include $(THEOS_MAKE_PATH)/tweak.mk