#import <UIKit/UIKit.h>
#import <dlfcn.h>
#import <mach/mach_time.h>
#import "AT10OverlayView.h"

typedef struct __IOHIDEvent *IOHIDEventRef;

typedef IOHIDEventRef (*IOHIDEventCreateDigitizerFingerEventFunc)(
    CFAllocatorRef, uint64_t, uint32_t, uint32_t, uint32_t,
    double, double, double, double, double,
    uint32_t, bool, bool, uint32_t
);

typedef void (*UIApplicationSendEventFunc)(UIApplication *, IOHIDEventRef);

static void simulateTap(CGPoint point) {
    void *handle = dlopen("/System/Library/PrivateFrameworks/BackBoardServices.framework/BackBoardServices", RTLD_LAZY);
    if (!handle) return;

    IOHIDEventCreateDigitizerFingerEventFunc createEvent =
        (IOHIDEventCreateDigitizerFingerEventFunc)dlsym(handle, "IOHIDEventCreateDigitizerFingerEvent");

    UIApplicationSendEventFunc sendEvent =
        (UIApplicationSendEventFunc)dlsym(RTLD_DEFAULT, "UIApplicationSendEvent");

    if (!createEvent || !sendEvent) { dlclose(handle); return; }

    CGSize screen = UIScreen.mainScreen.bounds.size;
    double x = point.x / screen.width;
    double y = point.y / screen.height;
    uint64_t ts = mach_absolute_time();

    IOHIDEventRef down = createEvent(kCFAllocatorDefault, ts, 0, 1, 0x3, x, y, 0, 1.0, 0, 1, true, false, 0);
    IOHIDEventRef up   = createEvent(kCFAllocatorDefault, ts + 1000000, 0, 1, 0x3, x, y, 0, 0.0, 0, 0, false, false, 0);

    if (down) { sendEvent(UIApplication.sharedApplication, down); CFRelease(down); }

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 20*NSEC_PER_MSEC), dispatch_get_main_queue(), ^{
        if (up) { sendEvent(UIApplication.sharedApplication, up); CFRelease(up); }
    });

    dlclose(handle);
}

__attribute__((constructor))
static void AT10AutoStart(void) {
    dispatch_after(
        dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)),
        dispatch_get_main_queue(),
        ^{
            AT10OverlayView *overlay = [AT10OverlayView sharedOverlay];
            overlay.onTap = ^(CGPoint position) {
                simulateTap(position);
            };
            [overlay showInView:nil];
        }
    );
}