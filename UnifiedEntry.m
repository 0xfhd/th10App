#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

extern void StartUnifiedMenu(void);

extern void StartProtection(void) __attribute__((weak_import));
extern void BatAuthCheck(void) __attribute__((weak_import));

extern void StartAutoClicker(void) __attribute__((weak_import));
extern void StartAnimationBooster(void) __attribute__((weak_import));

static void RunAuthFirst(void) {

    if (StartProtection) {
        StartProtection();
        return;
    }

    if (BatAuthCheck) {
        BatAuthCheck();
        return;
    }
}

static void RunModules(void) {

    if (StartAutoClicker) {
        StartAutoClicker();
    }

    if (StartAnimationBooster) {
        StartAnimationBooster();
    }

    StartUnifiedMenu();
}

__attribute__((constructor))
static void UnifiedStart(void) {

    @autoreleasepool {

        dispatch_after(
            dispatch_time(DISPATCH_TIME_NOW,
            2 * NSEC_PER_SEC),

            dispatch_get_main_queue(), ^{

            RunAuthFirst();

            dispatch_after(
                dispatch_time(DISPATCH_TIME_NOW,
                2 * NSEC_PER_SEC),

                dispatch_get_main_queue(), ^{

                RunModules();
            });
        });
    }
}