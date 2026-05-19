#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

extern void BatAuthCheck(void);

extern void StartAutoClicker(void);
extern void StartMikeFaceModule(void);
extern void StartMicUnlockModule(void);
extern void StartUnifiedSpeedBoost(void);

extern void StartUnifiedMenu(void);

__attribute__((constructor))
static void UnifiedStart(void) {

    @autoreleasepool {

        dispatch_after(
            dispatch_time(DISPATCH_TIME_NOW,
            1 * NSEC_PER_SEC),

            dispatch_get_main_queue(), ^{

            // الحماية أولاً
            BatAuthCheck();

            dispatch_after(
                dispatch_time(DISPATCH_TIME_NOW,
                2 * NSEC_PER_SEC),

                dispatch_get_main_queue(), ^{

                // الأوتو كلكر
                StartAutoClicker();

                // MikeFace
                StartMikeFaceModule();

                // MicUnlock
                StartMicUnlockModule();

                // Speed
                StartUnifiedSpeedBoost();

                // القائمة
                StartUnifiedMenu();
            });
        });
    }
}