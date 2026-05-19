#import <UIKit/UIKit.h>

extern void HubEnable(void);
extern void HubDisable(void);

static UIWindow *menuWindow;
static UIView *menuView;

@interface UnifiedMenu : NSObject
@end

@implementation UnifiedMenu

+ (instancetype)shared {

    static UnifiedMenu *m;
    static dispatch_once_t once;

    dispatch_once(&once, ^{
        m = [UnifiedMenu new];
    });

    return m;
}

- (void)toggle {
    menuView.hidden = !menuView.hidden;
}

- (void)link {
    HubEnable();
}

- (void)unlink {
    HubDisable();
}

- (void)hide {
    menuView.hidden = YES;
}

- (void)remove {

    [menuWindow removeFromSuperview];

    menuWindow = nil;
    menuView = nil;
}

@end

static UIButton *MakeButton(
NSString *title,
CGFloat y,
SEL action) {

    UIButton *btn =
    [UIButton buttonWithType:
    UIButtonTypeSystem];

    btn.frame =
    CGRectMake(15, y, 210, 40);

    btn.layer.cornerRadius = 12;

    btn.backgroundColor =
    [[UIColor blackColor]
    colorWithAlphaComponent:0.65];

    [btn setTitle:title
    forState:UIControlStateNormal];

    [btn setTitleColor:
    UIColor.whiteColor
    forState:UIControlStateNormal];

    [btn addTarget:
    [UnifiedMenu shared]
    action:action
    forControlEvents:
    UIControlEventTouchUpInside];

    return btn;
}

void StartUnifiedMenu(void) {

    dispatch_async(
    dispatch_get_main_queue(), ^{

        CGRect frame =
        UIScreen.mainScreen.bounds;

        menuWindow =
        [[UIWindow alloc]
        initWithFrame:frame];

        menuWindow.windowLevel =
        UIWindowLevelAlert + 999;

        UIViewController *vc =
        [UIViewController new];

        menuWindow.rootViewController = vc;

        menuWindow.hidden = NO;

        UIButton *open =
        [UIButton buttonWithType:
        UIButtonTypeSystem];

        open.frame =
        CGRectMake(
        (frame.size.width - 54) / 2,
        42,
        54,
        32);

        open.layer.cornerRadius = 12;

        open.backgroundColor =
        [[UIColor blackColor]
        colorWithAlphaComponent:0.75];

        [open setTitle:@"≡"
        forState:UIControlStateNormal];

        [open setTitleColor:
        UIColor.whiteColor
        forState:UIControlStateNormal];

        [open addTarget:
        [UnifiedMenu shared]
        action:@selector(toggle)
        forControlEvents:
        UIControlEventTouchUpInside];

        [vc.view addSubview:open];

        menuView =
        [[UIView alloc]
        initWithFrame:
        CGRectMake(
        (frame.size.width - 240) / 2,
        90,
        240,
        240)];

        menuView.layer.cornerRadius = 18;

        menuView.backgroundColor =
        [[UIColor blackColor]
        colorWithAlphaComponent:0.78];

        [vc.view addSubview:menuView];

        [menuView addSubview:
        MakeButton(
        @"Link Instances",
        20,
        @selector(link))];

        [menuView addSubview:
        MakeButton(
        @"Unlink",
        70,
        @selector(unlink))];

        [menuView addSubview:
        MakeButton(
        @"Hide Menu",
        120,
        @selector(hide))];

        [menuView addSubview:
        MakeButton(
        @"Remove UI",
        170,
        @selector(remove))];
    });
}