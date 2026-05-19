#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

extern void HubEnable(void);
extern void HubDisable(void);
extern void UnifiedMiniToggle(void);
extern BOOL UnifiedMiniIsEnabled(void);

static UIWindow *gUnifiedMenuWindow;
static UIView *gUnifiedMenuView;
static UIButton *gUnifiedOpenButton;
static UILabel *gUnifiedStatusLabel;
static UIButton *gMiniButton;

@interface UnifiedPassWindow : UIWindow
@end

@implementation UnifiedPassWindow
- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    if (!self.hidden && gUnifiedOpenButton) {
        CGPoint p = [gUnifiedOpenButton convertPoint:point fromView:self];
        if ([gUnifiedOpenButton pointInside:p withEvent:event]) return YES;
    }
    if (gUnifiedMenuView && !gUnifiedMenuView.hidden) {
        CGPoint p = [gUnifiedMenuView convertPoint:point fromView:self];
        if ([gUnifiedMenuView pointInside:p withEvent:event]) return YES;
    }
    return NO;
}
@end

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
    if (!gUnifiedMenuView) return;
    BOOL willShow = gUnifiedMenuView.hidden;
    if (willShow) {
        gUnifiedMenuView.hidden = NO;
        gUnifiedMenuView.alpha = 0.0;
        gUnifiedMenuView.transform = CGAffineTransformMakeScale(0.86, 0.86);
        [UIView animateWithDuration:0.22 delay:0 usingSpringWithDamping:0.82 initialSpringVelocity:0.45 options:0 animations:^{
            gUnifiedMenuView.alpha = 1.0;
            gUnifiedMenuView.transform = CGAffineTransformIdentity;
        } completion:nil];
    } else {
        [UIView animateWithDuration:0.16 animations:^{
            gUnifiedMenuView.alpha = 0.0;
            gUnifiedMenuView.transform = CGAffineTransformMakeScale(0.92, 0.92);
        } completion:^(BOOL finished) {
            gUnifiedMenuView.hidden = YES;
            gUnifiedMenuView.transform = CGAffineTransformIdentity;
        }];
    }
}

- (void)mini {
    UnifiedMiniToggle();
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 250 * NSEC_PER_MSEC), dispatch_get_main_queue(), ^{
        NSString *title = UnifiedMiniIsEnabled() ? @"إرجاع الشاشة" : @"تصغير الشاشة";
        [gMiniButton setTitle:title forState:UIControlStateNormal];
        gUnifiedStatusLabel.text = UnifiedMiniIsEnabled() ? @"الشاشة مصغرة" : @"الشاشة طبيعية";
    });
}

- (void)link {
    HubEnable();
    gUnifiedStatusLabel.text = @"الربط مفعل";
}

- (void)unlink {
    HubDisable();
    gUnifiedStatusLabel.text = @"الربط متوقف";
}

- (void)hide {
    [self toggle];
}

- (void)remove {
    [UIView animateWithDuration:0.18 animations:^{
        gUnifiedMenuWindow.alpha = 0.0;
    } completion:^(BOOL finished) {
        [gUnifiedMenuWindow removeFromSuperview];
        gUnifiedMenuWindow = nil;
        gUnifiedMenuView = nil;
        gUnifiedOpenButton = nil;
        gUnifiedStatusLabel = nil;
        gMiniButton = nil;
    }];
}

@end

static UILabel *UnifiedLabel(NSString *text, CGFloat y, CGFloat h, CGFloat size, BOOL bold) {
    UILabel *l = [[UILabel alloc] initWithFrame:CGRectMake(10, y, 200, h)];
    l.text = text;
    l.textAlignment = NSTextAlignmentCenter;
    l.textColor = UIColor.whiteColor;
    l.numberOfLines = 2;
    l.font = bold ? [UIFont boldSystemFontOfSize:size] : [UIFont systemFontOfSize:size weight:UIFontWeightRegular];
    return l;
}

static UIButton *UnifiedMakeButton(NSString *title, CGFloat y, SEL action) {
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
    btn.frame = CGRectMake(12, y, 196, 31);
    btn.layer.cornerRadius = 10;
    btn.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.12];
    btn.layer.borderWidth = 0.7;
    btn.layer.borderColor = [[UIColor whiteColor] colorWithAlphaComponent:0.20].CGColor;
    btn.titleLabel.font = [UIFont boldSystemFontOfSize:12];
    [btn setTitle:title forState:UIControlStateNormal];
    [btn setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    [btn addTarget:[UnifiedMenuController shared] action:action forControlEvents:UIControlEventTouchUpInside];
    return btn;
}

void StartUnifiedMenu(void) {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (gUnifiedMenuWindow) return;

        CGRect frame = UIScreen.mainScreen.bounds;
        gUnifiedMenuWindow = [[UnifiedPassWindow alloc] initWithFrame:frame];
        gUnifiedMenuWindow.windowLevel = UIWindowLevelAlert + 998;
        gUnifiedMenuWindow.backgroundColor = UIColor.clearColor;

        UIViewController *vc = [UIViewController new];
        vc.view.backgroundColor = UIColor.clearColor;
        gUnifiedMenuWindow.rootViewController = vc;
        gUnifiedMenuWindow.hidden = NO;

        gUnifiedOpenButton = [UIButton buttonWithType:UIButtonTypeSystem];
        gUnifiedOpenButton.frame = CGRectMake((frame.size.width - 46) / 2, 35, 46, 28);
        gUnifiedOpenButton.layer.cornerRadius = 14;
        gUnifiedOpenButton.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.62];
        gUnifiedOpenButton.layer.borderWidth = 0.8;
        gUnifiedOpenButton.layer.borderColor = [[UIColor whiteColor] colorWithAlphaComponent:0.22].CGColor;
        [gUnifiedOpenButton setTitle:@"⌗" forState:UIControlStateNormal];
        [gUnifiedOpenButton setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
        gUnifiedOpenButton.titleLabel.font = [UIFont boldSystemFontOfSize:18];
        [gUnifiedOpenButton addTarget:[UnifiedMenuController shared] action:@selector(toggle) forControlEvents:UIControlEventTouchUpInside];
        [vc.view addSubview:gUnifiedOpenButton];

        CGFloat panelW = 220;
        CGFloat panelH = 238;
        gUnifiedMenuView = [[UIView alloc] initWithFrame:CGRectMake((frame.size.width - panelW) / 2, 72, panelW, panelH)];
        gUnifiedMenuView.layer.cornerRadius = 18;
        gUnifiedMenuView.layer.masksToBounds = YES;
        gUnifiedMenuView.hidden = YES;

        CAGradientLayer *bg = [CAGradientLayer layer];
        bg.frame = gUnifiedMenuView.bounds;
        bg.colors = @[
            (id)[UIColor colorWithRed:0.04 green:0.05 blue:0.10 alpha:0.94].CGColor,
            (id)[UIColor colorWithRed:0.06 green:0.12 blue:0.22 alpha:0.94].CGColor,
            (id)[UIColor colorWithRed:0.02 green:0.02 blue:0.05 alpha:0.94].CGColor
        ];
        bg.startPoint = CGPointMake(0,0);
        bg.endPoint = CGPointMake(1,1);
        [gUnifiedMenuView.layer insertSublayer:bg atIndex:0];

        [vc.view addSubview:gUnifiedMenuView];

        UILabel *title = UnifiedLabel(@"⌗ أستحالة إلمقاطي ..", 10, 24, 13, YES);
        [gUnifiedMenuView addSubview:title];

        UILabel *group = UnifiedLabel(@"⌗ 10th battalión", 32, 20, 11, NO);
        group.textColor = [[UIColor whiteColor] colorWithAlphaComponent:0.82];
        [gUnifiedMenuView addSubview:group];

        gUnifiedStatusLabel = UnifiedLabel(@"جاهز", 54, 18, 10, NO);
        gUnifiedStatusLabel.textColor = [[UIColor whiteColor] colorWithAlphaComponent:0.70];
        [gUnifiedMenuView addSubview:gUnifiedStatusLabel];

        gMiniButton = UnifiedMakeButton(@"تصغير الشاشة", 78, @selector(mini));
        [gUnifiedMenuView addSubview:gMiniButton];

        [gUnifiedMenuView addSubview:UnifiedMakeButton(@"تفعيل الربط", 115, @selector(link))];
        [gUnifiedMenuView addSubview:UnifiedMakeButton(@"إيقاف الربط", 152, @selector(unlink))];
        [gUnifiedMenuView addSubview:UnifiedMakeButton(@"إخفاء القائمة", 189, @selector(hide))];
    });
}
