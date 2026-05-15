#import <UIKit/UIKit.h>
#import "AT10OverlayView.h"

__attribute__((constructor))
static void AT10AutoStart(void) {

    // نشغّل الأوفرلاي بعد ما اللعبة تجهز
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{

        UIWindow *targetWindow = nil;

        // نحاول نجيب نافذة اللعبة الأساسية من الـ scenes
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

        // احتياط: لو ما لقينا، نستخدم keyWindow القديمة
        if (!targetWindow)
            targetWindow = UIApplication.sharedApplication.keyWindow;

        // لو برضه ما فيه، نطلع
        if (!targetWindow)
            return;

        // نجيب الأوفرلاي المشترك
        AT10OverlayView *overlay = [AT10OverlayView sharedOverlay];

        // نخلي حجمه قد الشاشة
        overlay.frame = targetWindow.bounds;

        // مهم: ما يمنع اللمس عن اللعبة إلا في مناطقه
        overlay.userInteractionEnabled = YES;
        overlay.exclusiveTouch = NO;
        overlay.multipleTouchEnabled = YES;
        overlay.backgroundColor = UIColor.clearColor;

        // نعرضه فوق اللعبة
        [overlay showInView:targetWindow];
    });
}
