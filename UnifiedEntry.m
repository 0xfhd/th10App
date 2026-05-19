#import <UIKit/UIKit.h>

extern void StartUnifiedMenu(void);

__attribute__((constructor))
static void UnifiedStart(void) {

    @autoreleasepool {

        dispatch_after(
            dispatch_time(DISPATCH_TIME_NOW,
            2 * NSEC_PER_SEC),

            dispatch_get_main_queue(), ^{

            StartUnifiedMenu();
        });
    }
}