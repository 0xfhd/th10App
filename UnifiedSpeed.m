#import <UIKit/UIKit.h>

extern void SetSpeedEnabled(int enabled);

static BOOL gUnifiedSpeedApplied = NO;

static void UnifiedApplySpeed(void) {
    SetSpeedEnabled(1);
    for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
        if (![scene isKindOfClass:[UIWindowScene class]]) continue;
        for (UIWindow *w in ((UIWindowScene *)scene).windows) {
            if (w.windowLevel == UIWindowLevelNormal) {
                w.layer.speed = 15.0;
            }
        }
    }
    gUnifiedSpeedApplied = YES;
}

void StartUnifiedSpeedBoost(void) {
    dispatch_async(dispatch_get_main_queue(), ^{
        UnifiedApplySpeed();
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            UnifiedApplySpeed();
        });
    });
}

BOOL UnifiedSpeedApplied(void) {
    return gUnifiedSpeedApplied;
}
