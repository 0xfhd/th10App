#import <UIKit/UIKit.h>
#import "AT10OverlayView.h"

__attribute__((constructor))
static void AT10AutoStart(void) {
    dispatch_after(
        dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)),
        dispatch_get_main_queue(),
        ^{
            UIWindow *win = nil;
            for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
                if ([scene isKindOfClass:[UIWindowScene class]]) {
                    UIWindowScene *ws = (UIWindowScene *)scene;
                    for (UIWindow *w in ws.windows) {
                        if (w.isKeyWindow) { win = w; break; }
                    }
                }
            }
            if (!win) win = UIApplication.sharedApplication.keyWindow;
            if (win) {
                [[AT10OverlayView sharedOverlay] showInView:win];
            }
        }
    );
}
