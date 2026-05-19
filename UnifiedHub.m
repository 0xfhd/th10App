#import <Foundation/Foundation.h>
#import <notify.h>

static BOOL gUnifiedLinked = NO;

void HubEnable(void) {
    gUnifiedLinked = YES;
}

void HubDisable(void) {
    gUnifiedLinked = NO;
}

BOOL HubIsEnabled(void) {
    return gUnifiedLinked;
}

void HubBroadcast(NSString *event) {
    if (!gUnifiedLinked || event.length == 0) return;

    [[NSUserDefaults standardUserDefaults] setObject:event forKey:@"unified_event"];
    [[NSUserDefaults standardUserDefaults] synchronize];

    notify_post("com.unified.realmerge.hub");
}
