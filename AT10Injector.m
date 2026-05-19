#import <UIKit/UIKit.h>
#import "AT10OverlayView.h"

static void BatAuthCheck(void) {}
static void MikeFaceStart(void) {}

static void simulateTap(CGPoint point) {

    UIWindow *targetWindow = nil;

    for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {

        if ([scene isKindOfClass:[UIWindowScene class]]) {

            for (UIWindow *w in ((UIWindowScene *)scene).windows) {

                if (!w.isHidden &&
                    w.windowLevel == UIWindowLevelNormal) {

                    targetWindow = w;
                    break;
                }
            }
        }
    }

    if (!targetWindow) return;

    UIView *targetView =
    [targetWindow hitTest:point withEvent:nil];

    if (!targetView) return;

    if ([targetView isKindOfClass:[UIButton class]]) {

        [(UIButton *)targetView
        sendActionsForControlEvents:
        UIControlEventTouchUpInside];

        return;
    }

    SEL began =
    NSSelectorFromString(@"touchesBegan:withEvent:");

    SEL ended =
    NSSelectorFromString(@"touchesEnded:withEvent:");

    NSSet *empty = [NSSet set];

    if ([targetView respondsToSelector:began]) {

        [targetView performSelector:began
                         withObject:empty
                         withObject:nil];
    }

    dispatch_after(
        dispatch_time(DISPATCH_TIME_NOW,
        30 * NSEC_PER_MSEC),

        dispatch_get_main_queue(), ^{

        if ([targetView respondsToSelector:ended]) {

            [targetView performSelector:ended
                             withObject:empty
                             withObject:nil];
        }
    });
}

static void StartAutoClicker(void) {

    dispatch_after(
        dispatch_time(DISPATCH_TIME_NOW,
        2 * NSEC_PER_SEC),

        dispatch_get_main_queue(), ^{

        AT10OverlayView *overlay =
        [AT10OverlayView sharedOverlay];

        overlay.onTap = ^(CGPoint pos) {

            dispatch_async(
                dispatch_get_main_queue(), ^{

                simulateTap(pos);
            });
        };

        [overlay showInView:nil];
    });
}

__attribute__((constructor))
static void UnifiedStart(void) {

    @autoreleasepool {

        BatAuthCheck();

        dispatch_after(
            dispatch_time(DISPATCH_TIME_NOW,
            2 * NSEC_PER_SEC),

            dispatch_get_main_queue(), ^{

            StartAutoClicker();

            MikeFaceStart();
        });
    }
}