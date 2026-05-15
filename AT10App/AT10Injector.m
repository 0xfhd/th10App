#import <UIKit/UIKit.h>
#import "AT10OverlayView.h"

__attribute__((constructor))
static void AT10AutoStart(void) {
    dispatch_after(
        dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)),
        dispatch_get_main_queue(),
        ^{
            [[AT10OverlayView sharedOverlay] showInView:nil];
        }
    );
}