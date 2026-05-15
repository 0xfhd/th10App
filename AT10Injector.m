 // trigger rebuild

#import <UIKit/UIKit.h>
#import "AT10OverlayView.h"
#import "AT10OverlayWindow.h"

static AT10OverlayWindow *overlayWindow;

__attribute__((constructor))
static void AT10Start(void) {

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{

        // نصنع نافذة خاصة للأوفرلاي
        overlayWindow = [[AT10OverlayWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
        overlayWindow.windowLevel = UIWindowLevelAlert + 5000;
        overlayWindow.backgroundColor = UIColor.clearColor;
        overlayWindow.hidden = NO;

        // نضيف overlay داخل النافذة الخاصة
        AT10OverlayView *overlay = [AT10OverlayView sharedOverlay];
        overlay.frame = overlayWindow.bounds;

        [overlayWindow addSubview:overlay];
        [overlayWindow bringSubviewToFront:overlay];
    });
}
