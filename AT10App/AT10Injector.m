#import <UIKit/UIKit.h>
#import "AT10OverlayView.h"
#import <mach/mach_time.h>

typedef struct __IOHIDEvent *IOHIDEventRef;

extern IOHIDEventRef IOHIDEventCreateDigitizerFingerEvent(
    CFAllocatorRef allocator,
    uint64_t timeStamp,
    uint32_t index,
    uint32_t identity,
    uint32_t eventMask,
    double x, double y, double z,
    double tipPressure, double twist,
    uint32_t range, bool touch,
    bool ignorance, uint32_t options
);

extern void IOHIDEventSetIntegerValue(IOHIDEventRef event, int field, int value);
extern CFTypeRef UIApplicationSendEvent(UIApplication *app, IOHIDEventRef event);

static void simulateTap(CGPoint point) {
    CGSize screen = UIScreen.mainScreen.bounds.size;
    double x = point.x / screen.width;
    double y = point.y / screen.height;
    uint64_t ts = mach_absolute_time();

    IOHIDEventRef down = IOHIDEventCreateDigitizerFingerEvent(
        kCFAllocatorDefault, ts, 0, 1, 0x3,
        x, y, 0, 1.0, 0, 1, true, false, 0
    );
    IOHIDEventRef up = IOHIDEventCreateDigitizerFingerEvent(
        kCFAllocatorDefault, ts + 1000000, 0, 1, 0x3,
        x, y, 0, 0.0, 0, 0, false, false, 0
    );

    if (down) {
        UIApplicationSendEvent(UIApplication.sharedApplication, down);
        CFRelease(down);
    }
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 20*NSEC_PER_MSEC), dispatch_get_main_queue(), ^{
        if (up) {
            UIApplicationSendEvent(UIApplication.sharedApplication, up);
            CFRelease(up);
        }
    });
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