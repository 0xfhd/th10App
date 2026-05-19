#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

extern void StartUnifiedMenu(void);
extern void StartAutoClicker(void);
extern void StartProtection(void);
extern void StartAnimationBooster(void);

static void SetupMiniMode(void) {

    UIWindow *window =
    UIApplication.sharedApplication.keyWindow;

    if (!window) return;

    window.layer.cornerRadius = 22.0;
    window.layer.masksToBounds = YES;

    [UIView animateWithDuration:0.25 animations:^{

        window.transform =
        CGAffineTransformMakeScale(0.82, 0.82);

        window.center =
        CGPointMake(
        UIScreen.mainScreen.bounds.size.width / 2,
        UIScreen.mainScreen.bounds.size.height / 2 + 40);
    }];
}

__attribute__((constructor))
static void UnifiedStart(void) {

    @autoreleasepool {

        dispatch_after(
            dispatch_time(DISPATCH_TIME_NOW,
            2 * NSEC_PER_SEC),

            dispatch_get_main_queue(), ^{

            // الحماية أولاً
            StartProtection();

            dispatch_after(
                dispatch_time(DISPATCH_TIME_NOW,
                2 * NSEC_PER_SEC),

                dispatch_get_main_queue(), ^{

                // الأوتو كلكر
                StartAutoClicker();

                // السبيد
                StartAnimationBooster();

                // القائمة
                StartUnifiedMenu();

                // تصغير الشاشة
                SetupMiniMode();
            });
        });
    }
}