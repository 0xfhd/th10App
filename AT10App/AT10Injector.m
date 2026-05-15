#import <UIKit/UIKit.h>
#import <dlfcn.h>
#import <mach/mach_time.h>
#import "AT10OverlayView.h"

static void simulateTap(CGPoint point) {
    // نجيب الـ window الأساسية للتطبيق (مو نافذتنا)
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

    // نجيب الـ view اللي تحت نقطة الضغط
    UIView *targetView = [targetWindow hitTest:point withEvent:nil];
    if (!targetView) targetView = targetWindow;

    // نرسل اللمس مباشرة للـ view
    dispatch_async(dispatch_get_main_queue(), ^{
        // began
        NSSet *touches = [NSSet set];
        UIEvent *event = [[UIEvent alloc] init];

        // نستخدم performSelector عشان نتجنب private API في البناء
        SEL touchesBegan = NSSelectorFromString(@"touchesBegan:withEvent:");
        SEL touchesEnded = NSSelectorFromString(@"touchesEnded:withEvent:");

        if ([targetView respondsToSelector:touchesBegan]) {
            [targetView performSelector:touchesBegan withObject:touches withObject:event];
        }
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 30*NSEC_PER_MSEC), dispatch_get_main_queue(), ^{
            if ([targetView respondsToSelector:touchesEnded]) {
                [targetView performSelector:touchesEnded withObject:touches withObject:event];
            }
        });
    });
}

__attribute__((constructor))
static void AT10Aut