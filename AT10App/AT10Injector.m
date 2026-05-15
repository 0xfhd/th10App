#import <UIKit/UIKit.h>
#import "AT10OverlayView.h"

__attribute__((constructor))
static void AT10Start(void) {

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{

        UIWindow *targetWindow = nil;

        // نحصل نافذة اللعبة الأساسية
        for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
            if ([scene isKindOfClass:[UIWindowScene class]]) {
                UIWindowScene *ws = (UIWindowScene *)scene;

                for (UIWindow *w in ws.windows) {
                    if (w.isKeyWindow) {
                        targetWindow = w;
                        break;
                    }
                }
            }
            if (targetWindow) break;
        }

        if (!targetWindow)
            targetWindow = UIApplication.sharedApplication.keyWindow;

        if (!targetWindow)
            return;

        AT10OverlayView *overlay = [AT10OverlayView sharedOverlay];
        overlay.frame = targetWindow.bounds;

        [targetWindow addSubview:overlay];
        [targetWindow bringSubviewToFront:overlay];
    });
}
