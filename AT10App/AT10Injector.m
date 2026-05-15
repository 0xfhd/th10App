#import <UIKit/UIKit.h>
#import "AT10OverlayView.h"

static void simulateTap(CGPoint point) {
    UIWindow *targetWindow = nil;
    for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
        if ([scene isKindOfClass:[UIWindowScene class]]) {
            for (UIWindow *w in ((UIWindowScene *)scene).windows) {
                if (!w.isHidden && w.windowLevel == UIWindowLevelNormal) {
                    targetWindow = w;
                    break;
                }
            }
        }
    }
    if (!targetWindow) return;

    UIView *targetView = [targetWindow hitTest:point withEvent:nil];
    if (!targetView) return;

    // اذا كان زر نضغطه مباشرة
    if ([targetView isKindOfClass:[UIButton class]]) {
        [(UIButton *)targetView sendActionsForControlEvents:UIControlEventTouchUpInside];
        return;
    }

    // غير كذا نرسل notification
    [[NSNotificationCenter defaultCenter]
        postNotificationName:@"AT10TapNotification"
        object:nil
        userInfo:@{@"point": [NSValue valueWithCGPoint:point],
                   @"view": targetView}];
}

__attribute__((constructor))
static void autoStart(void) {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)),
        dispatch_get_main_queue(), ^{
            AT10OverlayView *overlay = [AT10OverlayView sharedOverlay];
            overlay.onTap = ^(CGPoint pos) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    simulateTap(pos);
                });
            };
            [overlay showInView:nil];
        });
}