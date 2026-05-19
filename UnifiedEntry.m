#import <UIKit/UIKit.h>
#import "AT10OverlayView.h"

extern void BatAuthCheck(void);
extern BOOL BatAuthIsApproved(void);

extern void StartUnifiedMenu(void);
extern void StartUnifiedSpeedBoost(void);
extern void StartMikeFaceModule(void);
extern void StartMicUnlockModule(void);

static BOOL gUnifiedModulesStarted = NO;

static UIWindow *UnifiedMainWindow(void) {
    for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
        if (![scene isKindOfClass:[UIWindowScene class]]) continue;
        for (UIWindow *w in ((UIWindowScene *)scene).windows) {
            if (!w.isHidden && w.windowLevel == UIWindowLevelNormal &&
                w.bounds.size.width > 0 && w.bounds.size.height > 0) {
                return w;
            }
        }
    }
    return UIApplication.sharedApplication.keyWindow;
}

static void UnifiedSimulateTap(CGPoint point) {
    UIWindow *targetWindow = UnifiedMainWindow();
    if (!targetWindow) return;

    UIView *targetView = [targetWindow hitTest:point withEvent:nil];
    if (!targetView) return;

    if ([targetView isKindOfClass:[UIButton class]]) {
        [(UIButton *)targetView sendActionsForControlEvents:UIControlEventTouchUpInside];
        return;
    }

    SEL began = NSSelectorFromString(@"touchesBegan:withEvent:");
    SEL ended = NSSelectorFromString(@"touchesEnded:withEvent:");
    NSSet *empty = [NSSet set];

    if ([targetView respondsToSelector:began]) {
        [targetView performSelector:began withObject:empty withObject:nil];
    }

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 30 * NSEC_PER_MSEC), dispatch_get_main_queue(), ^{
        if ([targetView respondsToSelector:ended]) {
            [targetView performSelector:ended withObject:empty withObject:nil];
        }
    });
}

static void StartUnifiedAutoClicker(void) {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *win = UnifiedMainWindow();
        if (!win) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                StartUnifiedAutoClicker();
            });
            return;
        }

        AT10OverlayView *overlay = [AT10OverlayView sharedOverlay];
        overlay.onTap = ^(CGPoint pos) {
            dispatch_async(dispatch_get_main_queue(), ^{
                UnifiedSimulateTap(pos);
            });
        };
        overlay.credit = @"⌗ أستحالة إلمقاطي ..\n⌗ 10th battalión";
        [overlay showInView:win];
    });
}

static void StartAllUnifiedModules(void) {
    if (gUnifiedModulesStarted) return;
    gUnifiedModulesStarted = YES;

    StartUnifiedSpeedBoost();
    StartUnifiedMenu();
    StartUnifiedAutoClicker();
    StartMikeFaceModule();
    StartMicUnlockModule();
}

static void WaitForAuthThenStart(void) {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 700 * NSEC_PER_MSEC), dispatch_get_main_queue(), ^{
        if (BatAuthIsApproved()) {
            StartAllUnifiedModules();
        } else {
            WaitForAuthThenStart();
        }
    });
}

__attribute__((constructor))
static void UnifiedRealMergeStart(void) {
    @autoreleasepool {
        dispatch_async(dispatch_get_main_queue(), ^{
            BatAuthCheck();
            WaitForAuthThenStart();
        });
    }
}
