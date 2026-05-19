#import <UIKit/UIKit.h>
#import "AT10OverlayView.h"

void StartAutoClicker(void) {

    dispatch_after(
        dispatch_time(DISPATCH_TIME_NOW,
        1 * NSEC_PER_SEC),

        dispatch_get_main_queue(), ^{

        AT10OverlayView *overlay =
        [AT10OverlayView sharedOverlay];

        overlay.onTap = ^(CGPoint pos) {

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

            UIView *target =
            [targetWindow hitTest:pos
                        withEvent:nil];

            if (!target) return;

            if ([target isKindOfClass:[UIButton class]]) {

                [(UIButton *)target
                sendActionsForControlEvents:
                UIControlEventTouchUpInside];

                return;
            }

            SEL began =
            NSSelectorFromString(
            @"touchesBegan:withEvent:");

            SEL ended =
            NSSelectorFromString(
            @"touchesEnded:withEvent:");

            NSSet *empty =
            [NSSet set];

            if ([target respondsToSelector:began]) {

                [target performSelector:began
                             withObject:empty
                             withObject:nil];
            }

            dispatch_after(
                dispatch_time(DISPATCH_TIME_NOW,
                40 * NSEC_PER_MSEC),

                dispatch_get_main_queue(), ^{

                if ([target respondsToSelector:ended]) {

                    [target performSelector:ended
                                 withObject:empty
                                 withObject:nil];
                }
            });
        };

        [overlay showInView:nil];
    });
}