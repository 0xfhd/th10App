#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <dlfcn.h>

extern void StartUnifiedMenu(void);

typedef void (*VoidFunc)(void);

static void CallIfExists(const char *name) {
    VoidFunc fn = (VoidFunc)dlsym(RTLD_DEFAULT, name);
    if (fn) {
        fn();
    }
}

static void RunAuthFirst(void) {
    CallIfExists("StartProtection");
    CallIfExists("BatAuthCheck");
}

static void RunModules(void) {
    CallIfExists("StartAutoClicker");
    CallIfExists("StartAnimationBooster");
    CallIfExists("MikeFaceStart");
    CallIfExists("MicUnlockStart");

    StartUnifiedMenu();
}

__attribute__((constructor))
static void UnifiedStart(void) {
    @autoreleasepool {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC),
        dispatch_get_main_queue(), ^{
            RunAuthFirst();

            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC),
            dispatch_get_main_queue(), ^{
                RunModules();
            });
        });
    }
}