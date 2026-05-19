#import <UIKit/UIKit.h>

extern void HubEnable(void);
extern void HubDisable(void);

static UIWindow *gUnifiedMenuWindow;
static UIView *gUnifiedMenuView;
static UIButton *gUnifiedOpenButton;
static UILabel *gUnifiedStatusLabel;

@interface UnifiedPassWindow : UIWindow
@end

@implementation UnifiedPassWindow
- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    if (!self.hidden && gUnifiedOpenButton) {
        CGPoint p = [gUnifiedOpenButton convertPoint:point fromView:self];
        if ([gUnifiedOpenButton pointInside:p withEvent:event]) return YES;
    }
    if (!gUnifiedMenuView.hidden && gUnifiedMenuView) {
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
    gUnifiedMenuView.hidden = !gUnifiedMenuView.hidden;
}

- (void)link {
    HubEnable();
    gUnifiedStatusLabel.text = @"الحالة: الربط مفعل";
}

- (void)unlink {
    HubDisable();
    gUnifiedStatusLabel.text = @"الحالة: الربط متوقف";
}

- (void)hide {
    gUnifiedMenuView.hidden = YES;
}

- (void)remove {
    [gUnifiedMenuWindow removeFromSuperview];
    gUnifiedMenuWindow = nil;
    gUnifiedMenuView = nil;
    gUnifiedOpenButton = nil;
    gUnifiedStatusLabel = nil;
}

@end

static UILabel *UnifiedLabel(NSString *text, CGFloat y, CGFloat h, CGFloat size, BOOL bold) {
    UILabel *l = [[UILabel alloc] initWithFrame:CGRectMake(14, y, 252, h)];
    l.text = text;
    l.textAlignment = NSTextAlignmentCenter;
    l.textColor = UIColor.whiteColor;
    l.numberOfLines = 2;
    l.font = bold ? [UIFont boldSystemFontOfSize:size] : [UIFont systemFontOfSize:size];
    return l;
}

static UIButton *UnifiedMakeButton(NSString *title, CGFloat y, SEL action) {
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
    btn.frame = CGRectMake(15, y, 250, 42);
    btn.layer.cornerRadius = 13;
    btn.backgroundColor = [[UIColor colorWithWhite:1 alpha:1] colorWithAlphaComponent:0.13];
    btn.layer.borderWidth = 0.8;
    btn.layer.borderColor = [[UIColor colorWithWhite:1 alpha:0.22] CGColor];
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
        gUnifiedMenuWindow = [[UnifiedPassWindow alloc] initWithFrame:frame];
        gUnifiedMenuWindow.windowLevel = UIWindowLevelAlert + 999;
        gUnifiedMenuWindow.backgroundColor = UIColor.clearColor;
        gUnifiedMenuWindow.userInteractionEnabled = YES;

        UIViewController *vc = [UIViewController new];
        vc.view.backgroundColor = UIColor.clearColor;
        gUnifiedMenuWindow.rootViewController = vc;
        gUnifiedMenuWindow.hidden = NO;

        gUnifiedOpenButton = [UIButton buttonWithType:UIButtonTypeSystem];
        gUnifiedOpenButton.frame = CGRectMake((frame.size.width - 60) / 2, 42, 60, 34);
        gUnifiedOpenButton.layer.cornerRadius = 14;
        gUnifiedOpenButton.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.72];
        gUnifiedOpenButton.layer.borderWidth = 0.8;
        gUnifiedOpenButton.layer.borderColor = [[UIColor colorWithWhite:1 alpha:0.28] CGColor];
        [gUnifiedOpenButton setTitle:@"10th" forState:UIControlStateNormal];
        [gUnifiedOpenButton setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
        gUnifiedOpenButton.titleLabel.font = [UIFont boldSystemFontOfSize:14];
        [gUnifiedOpenButton addTarget:[UnifiedMenuController shared] action:@selector(toggle) forControlEvents:UIControlEventTouchUpInside];
        [vc.view addSubview:gUnifiedOpenButton];

        gUnifiedMenuView = [[UIView alloc] initWithFrame:CGRectMake((frame.size.width - 280) / 2, 90, 280, 330)];
        gUnifiedMenuView.layer.cornerRadius = 22;
        gUnifiedMenuView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.82];
        gUnifiedMenuView.layer.borderWidth = 1.0;
        gUnifiedMenuView.layer.borderColor = [[UIColor colorWithWhite:1 alpha:0.18] CGColor];
        gUnifiedMenuView.hidden = YES;
        [vc.view addSubview:gUnifiedMenuView];

        [gUnifiedMenuView addSubview:UnifiedLabel(@"⌗ 10th battalión", 14, 24, 16, YES)];
        [gUnifiedMenuView addSubview:UnifiedLabel(@"⌗ أستحالة إلمقاطي ..", 40, 34, 13, NO)];

        gUnifiedStatusLabel = UnifiedLabel(@"الحالة: الربط متوقف", 76, 24, 12, NO);
        gUnifiedStatusLabel.textColor = [UIColor colorWithWhite:1 alpha:0.72];
        [gUnifiedMenuView addSubview:gUnifiedStatusLabel];

        [gUnifiedMenuView addSubview:UnifiedMakeButton(@"🔗 ربط النسخ", 112, @selector(link))];
        [gUnifiedMenuView addSubview:UnifiedMakeButton(@"🔓 فك الربط", 162, @selector(unlink))];
        [gUnifiedMenuView addSubview:UnifiedMakeButton(@"👁 إخفاء القائمة", 212, @selector(hide))];
        [gUnifiedMenuView addSubview:UnifiedMakeButton(@"❌ إزالة الواجهة", 262, @selector(remove))];
    });
}
