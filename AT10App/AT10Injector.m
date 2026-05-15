#import <UIKit/UIKit.h>
#import <dlfcn.h>
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
    if (!targetView) targetView = targetWindow;

    SEL began = NSSelectorFromString(@"touchesBegan:withEvent:");
    SEL ended = NSSelectorFromString(@"touchesEnded:withEvent:");
    NSSet *empty = [NSSet set];
    UIEvent *ev = [[UIEvent alloc] init];

    if ([targetView respondsToSelector:began])
        [targetView performSelector:began withObject:empty withObject:ev];

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 30*NSEC_PER_MSEC), dispatch_get_main_queue(), ^{
        if ([targetView respondsToSelector:ended])
            [targetView performSelector:ended withObject:empty withObject:ev];
    });
}

static void autoStart(void);

__attribute__((constructor)) static void autoStart(void) {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)),
        dispatch_get_main_queue(), ^{
            AT10OverlayView *overlay = [AT10OverlayView sharedOverlay];
            overlay.onTap = ^(CGPoint pos) { simulateTap(pos); };
            [overlay showInView:nil];
        });
}