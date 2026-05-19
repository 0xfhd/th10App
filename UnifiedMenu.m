#import <UIKit/UIKit.h>

extern void HubEnable(void);
extern void HubDisable(void);

static UIWindow *gUnifiedMenuWindow;
static UIView *gUnifiedMenuView;

@interface UnifiedMenuController : NSObject
@end

@implementation UnifiedMenuController

+ (instancetype)shared {
    static UnifiedMenuController *obj;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ obj = [UnifiedMenuController new]; });
    return obj;
}

- (void)toggle {
    gUnifiedMenuView.hidden = !gUnifiedMenuView.hidden;
}

- (void)link {
    HubEnable();
}

- (void)unlink {
    HubDisable();
}

- (void)hide {
    gUnifiedMenuView.hidden = YES;
}

- (void)remove {
    [gUnifiedMenuWindow removeFromSuperview];
    gUnifiedMenuWindow = nil;
    gUnifiedMenuView = nil;
}

@end

static UIButton *UnifiedMakeButton(NSString *title, CGFloat y, SEL action) {
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
    btn.frame = CGRectMake(15, y, 210, 40);
    btn.layer.cornerRadius = 12;
    btn.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.65];
    [btn setTitle:title forState:UIControlStateNormal];
    [btn setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    btn.titleLabel.font = [UIFont boldSystemFontOfSize:14];
    [btn addTarget:[UnifiedMenuController shared] action:action forControlEvents:UIControlEventTouchUpInside];
    return btn;
}

void StartUnifiedMenu(void) {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (gUnifiedMenuWindow) return;

        CGRect frame = UIScreen.mainScreen.bounds;
        gUnifiedMenuWindow = [[UIWindow alloc] initWithFrame:frame];
        gUnifiedMenuWindow.windowLevel = UIWindowLevelAlert + 999;
        gUnifiedMenuWindow.backgroundColor = UIColor.clearColor;

        UIViewController *vc = [UIViewController new];
        vc.view.backgroundColor = UIColor.clearColor;
        gUnifiedMenuWindow.rootViewController = vc;
        gUnifiedMenuWindow.hidden = NO;

        UIButton *open = [UIButton buttonWithType:UIButtonTypeSystem];
        open.frame = CGRectMake((frame.size.width - 54) / 2, 42, 54, 32);
        open.layer.cornerRadius = 12;
        open.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.75];
        [open setTitle:@"≡" forState:UIControlStateNormal];
        [open setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
        open.titleLabel.font = [UIFont boldSystemFontOfSize:20];
        [open addTarget:[UnifiedMenuController shared] action:@selector(toggle) forControlEvents:UIControlEventTouchUpInside];
        [vc.view addSubview:open];

        gUnifiedMenuView = [[UIView alloc] initWithFrame:CGRectMake((frame.size.width - 240) / 2, 90, 240, 240)];
        gUnifiedMenuView.layer.cornerRadius = 18;
        gUnifiedMenuView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.78];
        [vc.view addSubview:gUnifiedMenuView];

        [gUnifiedMenuView addSubview:UnifiedMakeButton(@"Link Instances", 20, @selector(link))];
        [gUnifiedMenuView addSubview:UnifiedMakeButton(@"Unlink", 70, @selector(unlink))];
        [gUnifiedMenuView addSubview:UnifiedMakeButton(@"Hide Menu", 120, @selector(hide))];
        [gUnifiedMenuView addSubview:UnifiedMakeButton(@"Remove UI", 170, @selector(remove))];
    });
}
