#import <UIKit/UIKit.h>

#define SPEED_KEY @"speedEnabled"

static BOOL speedEnabled = NO;
static BOOL menuOpen = NO;
static UIButton *speedButton = nil;
static UIView *menuView = nil;
static UIWindow *overlayWindow = nil;
static UIWindow *hideButtonWindow = nil;

@interface FlyController : UIViewController
- (void)applySpeed;
@end

@interface HideController : UIViewController
@end

@interface ShowController : UIViewController
@end

static FlyController *controller = nil;
static HideController *hc = nil;
static ShowController *sc = nil;

@implementation HideController
- (void)hideTapped {
    overlayWindow.hidden = YES;
    menuOpen = NO;
    menuView.alpha = 0;
    hideButtonWindow.hidden = NO;
}
@end

@implementation ShowController
- (void)showTapped {
    overlayWindow.hidden = NO;
    hideButtonWindow.hidden = YES;
}
@end

@implementation FlyController

- (void)flyTapped {
    menuOpen = !menuOpen;
    [UIView animateWithDuration:0.3 animations:^{
        menuView.alpha = menuOpen ? 1.0 : 0.0;
    }];
}

- (void)speedTapped {
    speedEnabled = !speedEnabled;
    [[NSUserDefaults standardUserDefaults] setBool:speedEnabled forKey:SPEED_KEY];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self applySpeed];
    if (speedEnabled) {
        [speedButton setTitle:@"✅ تم تفعيل السبيد" forState:UIControlStateNormal];
        speedButton.backgroundColor = [UIColor blackColor];
    } else {
        [speedButton setTitle:@"⚡ تفعيل السرعة" forState:UIControlStateNormal];
        speedButton.backgroundColor = [UIColor colorWithRed:0.1 green:0.4 blue:0.85 alpha:0.95];
    }
}

- (void)applySpeed {
    for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
        if ([scene isKindOfClass:[UIWindowScene class]]) {
            for (UIWindow *w in ((UIWindowScene *)scene).windows) {
                w.layer.speed = speedEnabled ? 15.0 : 1.0;
            }
        }
    }
    [UIView setAnimationsEnabled:!speedEnabled];
}

- (void)tgTapped {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://t.me/LJFNQ"] options:@{} completionHandler:nil];
}

@end

static void setupOverlay() {
    speedEnabled = [[NSUserDefaults standardUserDefaults] boolForKey:SPEED_KEY];

    CGRect screen = [UIScreen mainScreen].bounds;
    CGFloat w = 145;
    CGFloat h = 175;
    CGFloat x = screen.size.width - w - 10;
    CGFloat y = screen.size.height - h - 200;

    overlayWindow = [[UIWindow alloc] initWithFrame:CGRectMake(x, y, w, h)];
    overlayWindow.windowLevel = UIWindowLevelAlert + 100;
    overlayWindow.backgroundColor = [UIColor clearColor];
    overlayWindow.userInteractionEnabled = YES;
    controller = [[FlyController alloc] init];
    controller.view.backgroundColor = [UIColor clearColor];
    overlayWindow.rootViewController = controller;
    overlayWindow.hidden = NO;

    UIButton *flyButton = [UIButton buttonWithType:UIButtonTypeCustom];
    flyButton.frame = CGRectMake(0, 135, 140, 30);
    flyButton.layer.cornerRadius = 8;
    flyButton.backgroundColor = [UIColor colorWithRed:0.1 green:0.4 blue:0.85 alpha:0.95];
    flyButton.titleLabel.font = [UIFont boldSystemFontOfSize:11];
    [flyButton setTitle:@"⌗ 10th battalión" forState:UIControlStateNormal];
    [flyButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [flyButton addTarget:controller action:@selector(flyTapped) forControlEvents:UIControlEventTouchUpInside];
    [controller.view addSubview:flyButton];

    hc = [[HideController alloc] init];
    UIButton *hideBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    hideBtn.frame = CGRectMake(0, 100, 140, 30);
    hideBtn.layer.cornerRadius = 8;
    hideBtn.backgroundColor = [UIColor colorWithRed:0.2 green:0.2 blue:0.2 alpha:0.85];
    hideBtn.titleLabel.font = [UIFont boldSystemFontOfSize:11];
    [hideBtn setTitle:@"إخفاء القائمة" forState:UIControlStateNormal];
    [hideBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [hideBtn addTarget:hc action:@selector(hideTapped) forControlEvents:UIControlEventTouchUpInside];
    [controller.view addSubview:hideBtn];

    menuView = [[UIView alloc] initWithFrame:CGRectMake(0, 5, 140, 90)];
    menuView.backgroundColor = [UIColor clearColor];
    menuView.alpha = 0;
    menuView.userInteractionEnabled = YES;
    [controller.view addSubview:menuView];

    speedButton = [UIButton buttonWithType:UIButtonTypeCustom];
    speedButton.frame = CGRectMake(0, 0, 140, 40);
    speedButton.layer.cornerRadius = 10;
    speedButton.titleLabel.font = [UIFont boldSystemFontOfSize:12];
    if (speedEnabled) {
        speedButton.backgroundColor = [UIColor blackColor];
        [speedButton setTitle:@"✅ تم تفعيل السبيد" forState:UIControlStateNormal];
    } else {
        speedButton.backgroundColor = [UIColor colorWithRed:0.1 green:0.4 blue:0.85 alpha:0.95];
        [speedButton setTitle:@"⚡ تفعيل السرعة" forState:UIControlStateNormal];
    }
    [speedButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [speedButton addTarget:controller action:@selector(speedTapped) forControlEvents:UIControlEventTouchUpInside];
    [menuView addSubview:speedButton];

    UIButton *tgButton = [UIButton buttonWithType:UIButtonTypeCustom];
    tgButton.frame = CGRectMake(0, 48, 140, 40);
    tgButton.layer.cornerRadius = 10;
    tgButton.titleLabel.font = [UIFont boldSystemFontOfSize:12];
    tgButton.backgroundColor = [UIColor colorWithRed:0.0 green:0.48 blue:0.75 alpha:0.95];
    [tgButton setTitle:@"📩 ⌗ Fly .." forState:UIControlStateNormal];
    [tgButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [tgButton addTarget:controller action:@selector(tgTapped) forControlEvents:UIControlEventTouchUpInside];
    [menuView addSubview:tgButton];

    hideButtonWindow = [[UIWindow alloc] initWithFrame:CGRectMake(screen.size.width - 60, screen.size.height - 80, 50, 30)];
    hideButtonWindow.windowLevel = UIWindowLevelAlert + 99;
    hideButtonWindow.backgroundColor = [UIColor clearColor];
    hideButtonWindow.hidden = YES;
    sc = [[ShowController alloc] init];
    sc.view.backgroundColor = [UIColor clearColor];
    hideButtonWindow.rootViewController = sc;

    UIButton *showBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    showBtn.frame = CGRectMake(0, 0, 50, 30);
    showBtn.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.1];
    showBtn.layer.cornerRadius = 8;
    showBtn.titleLabel.font = [UIFont boldSystemFontOfSize:9];
    [showBtn setTitle:@"⌗" forState:UIControlStateNormal];
    [showBtn setTitleColor:[UIColor colorWithWhite:1.0 alpha:0.3] forState:UIControlStateNormal];
    [showBtn addTarget:sc action:@selector(showTapped) forControlEvents:UIControlEventTouchUpInside];
    [sc.view addSubview:showBtn];

    [controller applySpeed];
}

__attribute__((constructor))
static void init() {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        setupOverlay();
    });
}