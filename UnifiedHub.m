#import <Foundation/Foundation.h>
#import <notify.h>

static BOOL gLinked = NO;

void HubEnable(void) {
    gLinked = YES;
}

void HubDisable(void) {
    gLinked = NO;
}

void HubBroadcast(NSString *event) {

    if (!gLinked) return;

    [[NSUserDefaults standardUserDefaults]
    setObject:event
    forKey:@"unified_event"];

    [[NSUserDefaults standardUserDefaults]
    synchronize];

    notify_post("com.unified.hub");
}