#import <UIKit/UIKit.h>
#import <objc/runtime.h>

static BOOL gHideBG  = NO;
static BOOL gHideHUD = NO;
static CADisplayLink *gTicker;

static void saveState(void) {
    NSUserDefaults *d = [NSUserDefaults standardUserDefaults];
    [d setBool:gHideBG  forKey:@"bat_hideBG"];
    [d setBool:gHideHUD forKey:@"bat_hideHUD"];
    [d synchronize];
}

static void loadState(void) {
    NSUserDefaults *d = [NSUserDefaults standardUserDefaults];
    gHideBG  = [d boolForKey:@"bat_hideBG"];
    gHideHUD = [d boolForKey:@"bat_hideHUD"];
}

static UIWindow *getMainWindow(void) {
    for (UIScene *sc in UIApplication.sharedApplication.connectedScenes) {
        if (![sc isKindOfClass:[UIWindowScene class]]) continue;
        for (UIWindow *w in ((UIWindowScene *)sc).windows)
            if (w.isKeyWindow) return w;
    }
    return nil;
}

// Swizzle
static void (*orig_addSubview)(id, SEL, UIView *);
static void swizzled_addSubview(UIView *self, SEL _cmd, UIView *view) {
    orig_addSubview(self, _cmd, view);
    NSString *cls = NSStringFromClass(view.class);
    if (gHideHUD && [cls isEqualToString:@"MBProgressHUD"]) {
        view.hidden = YES; view.alpha = 0; view.frame = CGRectZero;
    }
    if (gHideBG && [cls isEqualToString:@"MBBackgroundView"]) {
        view.hidden = YES; view.alpha = 0; view.frame = CGRectZero;
    }
}

static void (*orig_setHidden)(id, SEL, BOOL);
static void swizzled_setHidden(UIView *self, SEL _cmd, BOOL hidden) {
    NSString *cls = NSStringFromClass(self.class);
    if (gHideHUD && [cls isEqualToString:@"MBProgressHUD"]) {
        orig_setHidden(self, _cmd, YES); self.alpha = 0; return;
    }
    if (gHideBG && [cls isEqualToString:@"MBBackgroundView"]) {
        orig_setHidden(self, _cmd, YES); self.alpha = 0; return;
    }
    orig_setHidden(self, _cmd, hidden);
}

static void (*orig_layoutSubviews)(id, SEL);
static void swizzled_layoutSubviews(UIView *self, SEL _cmd) {
    orig_layoutSubviews(self, _cmd);
    NSString *cls = NSStringFromClass(self.class);
    if (gHideHUD && [cls isEqualToString:@"MBProgressHUD"]) {
        self.hidden = YES; self.alpha = 0;
    }
    if (gHideBG && [cls isEqualToString:@"MBBackgroundView"]) {
        self.hidden = YES; self.alpha = 0;
    }
}

static void setupSwizzle(void) {
    Method m1 = class_getInstanceMethod([UIView class], @selector(addSubview:));
    orig_addSubview = (void *)method_getImplementation(m1);
    method_setImplementation(m1, (IMP)swizzled_addSubview);

    Method m2 = class_getInstanceMethod([UIView class], @selector(setHidden:));
    orig_setHidden = (void *)method_getImplementation(m2);
    method_setImplementation(m2, (IMP)swizzled_setHidden);

    Method m3 = class_getInstanceMethod([UIView class], @selector(layoutSubviews));
    orig_layoutSubviews = (void *)method_getImplementation(m3);
    method_setImplementation(m3, (IMP)swizzled_layoutSubviews);
}

static void scanView(UIView *view) {
    NSString *cls = NSStringFromClass(view.class);
    if ([cls isEqualToString:@"MBBackgroundView"]) {
        view.hidden = gHideBG; view.alpha = gHideBG ? 0 : 1;
    }
    if ([cls isEqualToString:@"MBProgressHUD"]) {
        view.hidden = gHideHUD; view.alpha = gHideHUD ? 0 : 1;
    }
    for (UIView *sub in view.subviews) scanView(sub);
}

static void applyHide(void) {
    dispatch_async(dispatch_get_main_queue(), ^{
        for (UIScene *sc in UIApplication.sharedApplication.connectedScenes) {
            if (![sc isKindOfClass:[UIWindowScene class]]) continue;
            for (UIWindow *win in ((UIWindowScene *)sc).windows)
                scanView(win);
        }
    });
}

@interface BatPanel : UIView
@property (nonatomic,strong) UIButton *btnBG;
@property (nonatomic,strong) UIButton *btnHUD;
@end

@implementation BatPanel

- (instancetype)init {
    self = [super initWithFrame:CGRectMake(0,0,200,0)];
    if (self) {
        self.backgroundColor = [UIColor colorWithWhite:0 alpha:0.88];
        self.layer.cornerRadius = 13;
        self.layer.borderWidth  = 1;
        self.layer.borderColor  = [UIColor colorWithWhite:1 alpha:0.15].CGColor;
        self.clipsToBounds = YES;
        self.userInteractionEnabled = YES;

        int y = 0;

        UIView *hdr = [[UIView alloc] initWithFrame:CGRectMake(0,0,200,32)];
        CAGradientLayer *g = [CAGradientLayer layer];
        g.frame = hdr.bounds;
        g.colors = @[
            (id)[UIColor colorWithRed:0.094 green:0.373 blue:0.647 alpha:1].CGColor,
            (id)[UIColor colorWithRed:0.216 green:0.541 blue:0.867 alpha:1].CGColor
        ];
        g.startPoint = CGPointMake(0,0.5);
        g.endPoint   = CGPointMake(1,0.5);
        [hdr.layer addSublayer:g];

        UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(0,0,200,32)];
        title.text = @"⌗ 10th battalión";
        title.font = [UIFont boldSystemFontOfSize:11];
        title.textColor = UIColor.whiteColor;
        title.textAlignment = NSTextAlignmentCenter;
        [hdr addSubview:title];
        [self addSubview:hdr];
        y += 32; y += 6;

        _btnBG = [self makeBtn:@"ازالة الصدم  ○" y:y];
        [_btnBG addTarget:self action:@selector(toggleBG)
            forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_btnBG];
        y += 34;

        _btnHUD = [self makeBtn:@"ازالة المغلق  ○" y:y];
        [_btnHUD addTarget:self action:@selector(toggleHUD)
            forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_btnHUD];
        y += 34;

        UIView *sep = [[UIView alloc] initWithFrame:CGRectMake(10,y,180,0.5)];
        sep.backgroundColor = [UIColor colorWithWhite:1 alpha:0.1];
        [self addSubview:sep];
        y += 8;

        UIButton *close = [self makeBtn:@"📲  إغلاق — @P511y" y:y];
        close.backgroundColor = [UIColor colorWithRed:0.0 green:0.38 blue:0.7 alpha:0.35];
        [close addTarget:self action:@selector(closeTapped)
            forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:close];
        y += 34; y += 6;

        self.frame = CGRectMake(0,0,200,y);
        [self updateBtnUI];
    }
    return self;
}

- (void)updateBtnUI {
    [_btnBG setTitle:[NSString stringWithFormat:@"ازالة الصدم  %@", gHideBG?@"●":@"○"]
            forState:UIControlStateNormal];
    _btnBG.backgroundColor = gHideBG ?
        [UIColor colorWithRed:0.094 green:0.373 blue:0.647 alpha:0.4] :
        [UIColor colorWithWhite:1 alpha:0.08];

    [_btnHUD setTitle:[NSString stringWithFormat:@"ازالة المغلق  %@", gHideHUD?@"●":@"○"]
             forState:UIControlStateNormal];
    _btnHUD.backgroundColor = gHideHUD ?
        [UIColor colorWithRed:0.094 green:0.373 blue:0.647 alpha:0.4] :
        [UIColor colorWithWhite:1 alpha:0.08];
}

- (UIButton *)makeBtn:(NSString *)t y:(int)y {
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    btn.frame = CGRectMake(8,y,184,28);
    btn.layer.cornerRadius = 7;
    btn.backgroundColor = [UIColor colorWithWhite:1 alpha:0.08];
    btn.layer.borderWidth = 0.8;
    btn.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.12].CGColor;
    btn.titleLabel.font = [UIFont boldSystemFontOfSize:10];
    [btn setTitle:t forState:UIControlStateNormal];
    [btn setTitleColor:[UIColor colorWithWhite:1 alpha:0.9] forState:UIControlStateNormal];
    btn.userInteractionEnabled = YES;
    return btn;
}

- (void)toggleBG {
    gHideBG = !gHideBG;
    saveState();
    [self updateBtnUI];
    [self updateTicker];
    applyHide();
}

- (void)toggleHUD {
    gHideHUD = !gHideHUD;
    saveState();
    [self updateBtnUI];
    [self updateTicker];
    applyHide();
}

- (void)updateTicker {
    if (gHideBG || gHideHUD) {
        if (!gTicker) {
            gTicker = [CADisplayLink displayLinkWithTarget:self selector:@selector(keep)];
            gTicker.preferredFramesPerSecond = 60;
            [gTicker addToRunLoop:NSRunLoop.mainRunLoop forMode:NSRunLoopCommonModes];
        }
    } else {
        [gTicker invalidate]; gTicker = nil;
    }
}

- (void)keep { applyHide(); }

- (void)closeTapped {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://t.me/P511y"]
        options:@{} completionHandler:nil];
    [UIView animateWithDuration:0.2 animations:^{ self.alpha = 0; }
        completion:^(BOOL f){ self.hidden = YES; self.alpha = 1; }];
}

@end

@interface BatTrigger : UIView
@property (nonatomic,strong) BatPanel *panel;
@end

@implementation BatTrigger

- (instancetype)init {
    self = [super initWithFrame:CGRectMake(0,0,32,32)];
    if (self) {
        self.userInteractionEnabled = YES;

        UIButton *sq = [UIButton buttonWithType:UIButtonTypeCustom];
        sq.frame = self.bounds;
        sq.backgroundColor = [UIColor colorWithWhite:0 alpha:0.82];
        sq.layer.cornerRadius = 8;
        sq.layer.borderWidth = 1.5;
        sq.layer.borderColor = [UIColor colorWithRed:0.094 green:0.373 blue:0.647 alpha:1].CGColor;
        sq.titleLabel.font = [UIFont boldSystemFontOfSize:9];
        [sq setTitle:@"⌗" forState:UIControlStateNormal];
        [sq setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
        [sq addTarget:self action:@selector(togglePanel)
            forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:sq];

        _panel = [[BatPanel alloc] init];
        _panel.hidden = YES;
        _panel.userInteractionEnabled = YES;

        UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc]
            initWithTarget:self action:@selector(pan:)];
        [self addGestureRecognizer:pan];
    }
    return self;
}

- (void)togglePanel {
    if (_panel.hidden) {
        UIWindow *win = getMainWindow();
        if (!win) return;
        CGRect myFrame = [self convertRect:self.bounds toView:win];
        CGFloat panelH = _panel.bounds.size.height;
        CGFloat x = MAX(8, myFrame.origin.x);
        CGFloat y = myFrame.origin.y - panelH - 4;
        if (y < 50) y = myFrame.origin.y + 36;
        _panel.frame = CGRectMake(x, y, 200, panelH);
        [win addSubview:_panel];
        [win bringSubviewToFront:_panel];
        _panel.hidden = NO;
    } else {
        _panel.hidden = YES;
        [_panel removeFromSuperview];
    }
}

- (void)pan:(UIPanGestureRecognizer *)g {
    CGPoint t = [g translationInView:self.superview];
    self.center = CGPointMake(
        MAX(16, MIN(self.superview.bounds.size.width-16, self.center.x+t.x)),
        MAX(16, MIN(self.superview.bounds.size.height-16, self.center.y+t.y))
    );
    [g setTranslation:CGPointZero inView:self.superview];
    _panel.hidden = YES;
    [_panel removeFromSuperview];
}

@end

void StartMicUnlockModule(void) {
    static BOOL didStart = NO;
    if (didStart) return;
    didStart = YES;
    setupSwizzle();

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.5 * NSEC_PER_SEC)),
        dispatch_get_main_queue(), ^{

        loadState();

        UIWindow *mainWin = getMainWindow();
        if (!mainWin) return;

        CGFloat screenH = mainWin.bounds.size.height;
        BatTrigger *trigger = [[BatTrigger alloc] init];
        trigger.center = CGPointMake(24, screenH - 120);
        [mainWin addSubview:trigger];
        [mainWin bringSubviewToFront:trigger];

        if (gHideBG || gHideHUD) {
            applyHide();
            [trigger.panel updateTicker];
        }

        [NSTimer scheduledTimerWithTimeInterval:1.0 repeats:YES block:^(NSTimer *t) {
            dispatch_async(dispatch_get_main_queue(), ^{
                UIWindow *w = getMainWindow();
                if (w) {
                    if (trigger.superview != w) [w addSubview:trigger];
                    [trigger.superview bringSubviewToFront:trigger];
                }
            });
        }];

        objc_setAssociatedObject(mainWin, "bat", trigger, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    });
}