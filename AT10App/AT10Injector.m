#import <UIKit/UIKit.h>
#import "AT10OverlayView.h"

// IOHIDEvent للمس الحقيقي
typedef struct __IOHIDEvent *IOHIDEventRef;
extern IOHIDEventRef IOHIDEventCreateDigitizerFingerEvent(CFAllocatorRef, uint64_t, uint32_t, uint32_t, uint32_t, double, double, double, double, double, uint32_t, bool, bool, uint32_t);
extern void UIApplicationSendEvent(UIApplication *, UIEvent *);
extern IOHIDEventRef IOHIDEventCreateDigitizerEvent(CFAllocatorRef, uint64_t, uint32_t, uint32_t, uint32_t, double, double, double, double, double, uint32_t, double, double, uint32_t, bool, bool, uint32_t);

static void simulateTap(CGPoint point) {
    UIWindow *win = nil;
    for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
        if ([scene isKindOfClass:[UIWindowScene class]]) {
            for (UIWindow *w in ((UIWindowScene *)scene).windows) {
                if (!w.isHidden && w.windowLevel == UIWindowLevelNormal) {
                    win = w; break;
                }
            }
        }
    }
    if (!win) return;

    // محاكاة لمس عبر sendEvent
    UITouch *touch = [[UITouch alloc] init];
    [touch setValue:@(UITouchPhaseBegan) forKey:@"phase"];
    [touch setValue:@(0.1) forKey:@"timestamp"];
    [touch setValue:win forKey:@"window"];
    [touch setValue:win forKey:@"view"];
    [touch setValue:[NSValue valueWithCGPoint:point] forKey:@"locationInWindow"];

    UIEvent *event = [[UIEvent alloc] init];
    [event setValue:[NSSet setWithObject:touch] forKey:@"_touches"];
    [win sendEvent:event];

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 10*NSEC_PER_MSEC), dispatch_get_main_queue(), ^{
        [touch setValue:@(UITouchPhaseEnded) forKey:@"phase"];
        [win sendEvent:event];
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