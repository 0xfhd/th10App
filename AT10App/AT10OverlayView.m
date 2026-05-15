#import "AT10OverlayView.h"
#import <QuartzCore/QuartzCore.h>

#define BLUE_DARK  [UIColor colorWithRed:0.094 green:0.373 blue:0.647 alpha:1]
#define BLUE_MID   [UIColor colorWithRed:0.216 green:0.541 blue:0.867 alpha:1]
#define BLACK_BTN  [UIColor colorWithRed:0.07 green:0.07 blue:0.07 alpha:1]
#define PW         170.0
#define MAX_DOTS   10

@interface AT10PassthroughWindow : UIWindow
@end
@implementation AT10PassthroughWindow
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *hit = [super hitTest:point withEvent:event];
    if (hit == self || hit == self.rootViewController.view) return nil;
    return hit;
}
@end

@interface AT10Dot : UIView
@property (nonatomic, assign) CGPoint dotPos;
@end
@implementation AT10Dot
@end

@interface AT10OverlayView()
@property (nonatomic,strong) NSMutableArray<AT10Dot *> *dots;
@property (nonatomic,strong) UIView        *panel;
@property (nonatomic,strong) UIButton      *toggleBtn;
@property (nonatomic,strong) UISlider      *speedSlider;
@property (nonatomic,strong) UILabel       *speedValLabel;
@property (nonatomic,strong) UIView        *panelBody;
@property (nonatomic,strong) UIButton      *collapseBtn;
@property (nonatomic,strong) UILabel       *dotCountLabel;
@property (nonatomic,assign) BOOL          collapsed;
@property (nonatomic,assign) BOOL          running;
@property (nonatomic,assign) NSInteger     cps;
@property (nonatomic,strong) CADisplayLink *ticker;
@property (nonatomic,assign) NSTimeInterval accumulator;
@property (nonatomic,strong) AT10PassthroughWindow *overlayWindow;
@end

@implementation AT10OverlayView

+ (instancetype)sharedOverlay {
    static AT10OverlayView *i;
    static dispatch_once_t t;
    dispatch_once(&t, ^{ i = [[self alloc] initWithFrame:CGRectZero]; });
    return i;
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *hit = [super hitTest:point withEvent:event];
    if (hit == self) return nil;
    return hit;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = UIColor.clearColor;
        self.userInteractionEnabled = YES;
        _cps = 30;
        _collapsed = YES;
        _dots = [NSMutableArray array];
        _credit = @"⌗ 10th | AsT7aLh | استحالة";
        [self buildPanel];
    }
    return self;
}

- (AT10Dot *)makeDotAt:(CGPoint)center {
    AT10Dot *dot = [[AT10Dot alloc] initWithFrame:CGRectMake(0,0,44,44)];
    dot.backgroundColor = [UIColor colorWithWhite:1 alpha:0.15];
    dot.layer.cornerRadius = 22;
    dot.layer.borderWidth = 1.8;
    dot.layer.borderColor = [UIColor colorWithRed:0.216 green:0.541 blue:0.867 alpha:0.6].CGColor;
    dot.layer.masksToBounds = YES;
    dot.dotPos = center;

    UILabel *lbl = [[UILabel alloc] initWithFrame:dot.bounds];
    lbl.text = @"⌗ 10th";
    lbl.font = [UIFont boldSystemFontOfSize:7];
    lbl.textColor = UIColor.blackColor;
    lbl.textAlignment = NSTextAlignmentCenter;
    lbl.numberOfLines = 2;
    [dot addSubview:lbl];

    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc]
        initWithTarget:self action:@selector(handleDotPan:)];
    [dot addGestureRecognizer:pan];

    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]
        initWithTarget:self action:@selector(dotTapped)];
    tap.numberOfTapsRequired = 1;
    [dot addGestureRecognizer:tap];

    dot.center = center;
    [self addSubview:dot];
    [_dots addObject:dot];
    return dot;
}

- (void)handleDotPan:(UIPanGestureRecognizer *)g {
    if (_running) return;
    AT10Dot *dot = (AT10Dot *)g.view;
    CGPoint t = [g translationInView:self];
    dot.center = CGPointMake(
        MAX(22, MIN(self.bounds.size.width-22,  dot.center.x + t.x)),
        MAX(22, MIN(self.bounds.size.height-22, dot.center.y + t.y))
    );
    dot.dotPos = dot.center;
    [g setTranslation:CGPointZero inView:self];
}

- (void)dotTapped {
    [self toggleCollapse];
}

- (void)buildPanel {
    _panel = [[UIView alloc] initWithFrame:CGRectMake(16,80,PW,30)];
    _panel.alpha = 0;
    _panel.backgroundColor = [UIColor colorWithWhite:0 alpha:0.72];
    _panel.layer.cornerRadius = 12;
    _panel.layer.borderWidth  = 1;
    _panel.layer.borderColor  = [UIColor colorWithWhite:1 alpha:0.12].CGColor;
    _panel.clipsToBounds = YES;

    // هيدر
    UIView *hdr = [[UIView alloc] initWithFrame:CGRectMake(0,0,PW,30)];
    CAGradientLayer *g = [CAGradientLayer layer];
    g.frame = hdr.bounds;
    g.colors = @[(id)BLUE_DARK.CGColor, (id)BLUE_MID.CGColor];
    g.startPoint = CGPointMake(0,0.5);
    g.endPoint   = CGPointMake(1,0.5);
    [hdr.layer addSublayer:g];

    UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(8,0,PW-36,30)];
    title.text = @"⌗ 10th — AsT7aLh";
    title.font = [UIFont boldSystemFontOfSize:9.5];
    title.textColor = UIColor.whiteColor;
    [hdr addSubview:title];

    _collapseBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    _collapseBtn.frame = CGRectMake(PW-28,5,22,20);
    _collapseBtn.backgroundColor = [UIColor colorWithWhite:1 alpha:0.18];
    _collapseBtn.layer.cornerRadius = 5;
    [_collapseBtn setTitle:@"▼" forState:UIControlStateNormal];
    _collapseBtn.titleLabel.font = [UIFont systemFontOfSize:9];
    [_collapseBtn addTarget:self action:@selector(toggleCollapse)
          forControlEvents:UIControlEventTouchUpInside];
    [hdr addSubview:_collapseBtn];

    UIPanGestureRecognizer *panG = [[UIPanGestureRecognizer alloc]
        initWithTarget:self action:@selector(handlePanelPan:)];
    [hdr addGestureRecognizer:panG];
    [_panel addSubview:hdr];

    // body
    _panelBody = [[UIView alloc] initWithFrame:CGRectMake(0,30,PW,200)];
    _panelBody.backgroundColor = UIColor.clearColor;
    _panelBody.alpha = 0;
    [_panel addSubview:_panelBody];

    CGFloat W = PW - 16;
    int y = 8;

    // زر التفعيل
    _toggleBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    _toggleBtn.frame = CGRectMake(8,y,W,32);
    _toggleBtn.layer.cornerRadius = 8;
    _toggleBtn.titleLabel.font = [UIFont boldSystemFontOfSize:12];
    [_toggleBtn setTitle:@"▶  تفعيل" forState:UIControlStateNormal];
    [_toggleBtn setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    [self setButtonBlue];
    [_toggleBtn addTarget:self action:@selector(toggleTapped)
        forControlEvents:UIControlEventTouchUpInside];
    [_panelBody addSubview:_toggleBtn];
    y += 38;

    // السرعة
    UILabel *spdTitle = [[UILabel alloc] initWithFrame:CGRectMake(8,y,W/2,14)];
    spdTitle.text = @"السرعة";
    spdTitle.font = [UIFont boldSystemFontOfSize:8.5];
    spdTitle.textColor = [UIColor colorWithWhite:1 alpha:0.6];
    [_panelBody addSubview:spdTitle];

    _speedValLabel = [[UILabel alloc] initWithFrame:CGRectMake(8+W/2,y,W/2,14)];
    _speedValLabel.text = @"متوسط";
    _speedValLabel.font = [UIFont boldSystemFontOfSize:8.5];
    _speedValLabel.textColor = UIColor.whiteColor;
    _speedValLabel.textAlignment = NSTextAlignmentRight;
    [_panelBody addSubview:_speedValLabel];
    y += 16;

    _speedSlider = [[UISlider alloc] initWithFrame:CGRectMake(8,y,W,22)];
    _speedSlider.minimumValue = 1;
    _speedSlider.maximumValue = 60;
    _speedSlider.value = 30;
    _speedSlider.tintColor = BLUE_MID;
    [_speedSlider addTarget:self action:@selector(speedChanged)
          forControlEvents:UIControlEventValueChanged];
    [_panelBody addSubview:_speedSlider];
    y += 22;

    UILabel *lSlow = [[UILabel alloc] initWithFrame:CGRectMake(8,y,W/2,12)];
    lSlow.text = @"أسرع";
    lSlow.font = [UIFont systemFontOfSize:7.5];
    lSlow.textColor = [UIColor colorWithWhite:1 alpha:0.4];
    [_panelBody addSubview:lSlow];

    UILabel *lFast = [[UILabel alloc] initWithFrame:CGRectMake(8+W/2,y,W/2,12)];
    lFast.text = @"أبطأ";
    lFast.font = [UIFont systemFontOfSize:7.5];
    lFast.textColor = lSlow.textColor;
    lFast.textAlignment = NSTextAlignmentRight;
    [_panelBody addSubview:lFast];
    y += 16;

    // فاصل
    UIView *sep = [[UIView alloc] initWithFrame:CGRectMake(8,y,W,0.5)];
    sep.backgroundColor = [UIColor colorWithWhite:1 alpha:0.1];
    [_panelBody addSubview:sep];
    y += 8;

    // زر إضافة دائرة
    UIButton *addDot = [UIButton buttonWithType:UIButtonTypeCustom];
    addDot.frame = CGRectMake(8,y,W,28);
    addDot.layer.cornerRadius = 7;
    addDot.backgroundColor = [UIColor colorWithWhite:1 alpha:0.1];
    addDot.layer.borderWidth = 0.8;
    addDot.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.2].CGColor;
    addDot.titleLabel.font = [UIFont boldSystemFontOfSize:11];
    [addDot setTitle:@"＋  دائرة جديدة" forState:UIControlStateNormal];
    [addDot setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    [addDot addTarget:self action:@selector(addDotTapped)
        forControlEvents:UIControlEventTouchUpInside];
    [_panelBody addSubview:addDot];
    y += 34;

    // عداد الدوائر
    _dotCountLabel = [[UILabel alloc] initWithFrame:CGRectMake(8,y,W,12)];
    _dotCountLabel.text = @"الدوائر: 1 / 10";
    _dotCountLabel.font = [UIFont systemFontOfSize:7.5];
    _dotCountLabel.textColor = [UIColor colorWithWhite:1 alpha:0.4];
    _dotCountLabel.textAlignment = NSTextAlignmentCenter;
    [_panelBody addSubview:_dotCountLabel];
    y += 16;

    // فاصل
    UIView *sep2 = [[UIView alloc] initWithFrame:CGRectMake(8,y,W,0.5)];
    sep2.backgroundColor = [UIColor colorWithWhite:1 alpha:0.1];
    [_panelBody addSubview:sep2];
    y += 8;

    // الحقوق
    UILabel *cr = [[UILabel alloc] initWithFrame:CGRectMake(8,y,W,12)];
    cr.text = @"⌗ 10th | AsT7aLh | استحالة";
    cr.font = [UIFont systemFontOfSize:7];
    cr.textColor = [UIColor colorWithWhite:1 alpha:0.35];
    cr.textAlignment = NSTextAlignmentCenter;
    [_panelBody addSubview:cr];
    y += 16;

    _panelBody.frame = CGRectMake(0,30,PW,y+6);
    [self addSubview:_panel];
}

- (void)addDotTapped {
    if (_dots.count >= MAX_DOTS) return;
    CGPoint c = CGPointMake(self.bounds.size.width/2 + (_dots.count * 15),
                             self.bounds.size.height/2);
    [self makeDotAt:c];
    _dotCountLabel.text = [NSString stringWithFormat:@"الدوائر: %lu / 10",
                           (unsigned long)_dots.count];
}

- (void)toggleCollapse {
    _collapsed = !_collapsed;
    [UIView animateWithDuration:0.2 animations:^{
        self->_panelBody.alpha = self->_collapsed ? 0 : 1;
        CGRect f = self->_panel.frame;
        f.size.height = self->_collapsed ? 30 : 30 + self->_panelBody.bounds.size.height;
        self->_panel.frame = f;
        self->_panel.alpha = self->_collapsed ? 0 : 1;
    }];
    [_collapseBtn setTitle:_collapsed ? @"▼" : @"▲" forState:UIControlStateNormal];
}

- (void)setButtonBlue {
    for (CALayer *l in _toggleBtn.layer.sublayers)
        if ([l isKindOfClass:[CAGradientLayer class]]) { [l removeFromSuperlayer]; break; }
    CAGradientLayer *g = [CAGradientLayer layer];
    g.frame = _toggleBtn.bounds;
    g.cornerRadius = 8;
    g.colors = @[(id)BLUE_DARK.CGColor, (id)BLUE_MID.CGColor];
    g.startPoint = CGPointMake(0,0.5);
    g.endPoint   = CGPointMake(1,0.5);
    [_toggleBtn.layer insertSublayer:g atIndex:0];
    _toggleBtn.backgroundColor = UIColor.clearColor;
}

- (void)setButtonBlack {
    for (CALayer *l in _toggleBtn.layer.sublayers)
        if ([l isKindOfClass:[CAGradientLayer class]]) { [l removeFromSuperlayer]; break; }
    _toggleBtn.backgroundColor = BLACK_BTN;
}

- (void)handlePanelPan:(UIPanGestureRecognizer *)g {
    CGPoint t = [g translationInView:self];
    _panel.center = CGPointMake(
        MAX(_panel.bounds.size.width/2, MIN(self.bounds.size.width - _panel.bounds.size.width/2, _panel.center.x + t.x)),
        MAX(_panel.bounds.size.height/2, MIN(self.bounds.size.height - _panel.bounds.size.height/2, _panel.center.y + t.y))
    );
    [g setTranslation:CGPointZero inView:self];
}

- (void)speedChanged {
    int v = (int)_speedSlider.value;
    _cps = v;
    if (v <= 15) _speedValLabel.text = @"بطيء";
    else if (v <= 35) _speedValLabel.text = @"متوسط";
    else if (v <= 50) _speedValLabel.text = @"سريع";
    else _speedValLabel.text = @"أقصى سرعة";
}

- (void)toggleTapped {
    if (!_running) {
        if (_dots.count == 0) return;
        _running = YES;
        _accumulator = 0;
        _ticker = [CADisplayLink displayLinkWithTarget:self selector:@selector(tick:)];
        _ticker.preferredFramesPerSecond = 0;
        [_ticker addToRunLoop:NSRunLoop.mainRunLoop forMode:NSRunLoopCommonModes];
        [self setButtonBlack];
        [_toggleBtn setTitle:@"⏹  إيقاف" forState:UIControlStateNormal];
    } else {
        _running = NO;
        [_ticker invalidate]; _ticker = nil;
        [self setButtonBlue];
        [_toggleBtn setTitle:@"▶  تفعيل" forState:UIControlStateNormal];
    }
}

- (void)tick:(CADisplayLink *)dl {
    if (!_running) return;
    _accumulator += dl.duration;
    double interval = 1.0 / MAX(1, _cps);
    while (_accumulator >= interval) {
        _accumulator -= interval;
        for (AT10Dot *dot in _dots) {
            if (self.onTap) self.onTap(dot.dotPos);
            dispatch_async(dispatch_get_main_queue(), ^{
                dot.backgroundColor = [UIColor colorWithRed:0.84 green:0.91 blue:0.97 alpha:0.4];
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 40*NSEC_PER_MSEC), dispatch_get_main_queue(), ^{
                    dot.backgroundColor = [UIColor colorWithWhite:1 alpha:0.15];
                });
            });
        }
    }
}

- (void)showInView:(UIView *)parentView {
    UIWindowScene *scene = nil;
    for (UIScene *s in UIApplication.sharedApplication.connectedScenes) {
        if ([s isKindOfClass:[UIWindowScene class]]) { scene = (UIWindowScene *)s; break; }
    }
    if (scene) {
        _overlayWindow = [[AT10PassthroughWindow alloc] initWithWindowScene:scene];
    } else {
        _overlayWindow = [[AT10PassthroughWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
    }
    _overlayWindow.windowLevel = UIWindowLevelAlert + 1;
    _overlayWindow.backgroundColor = UIColor.clearColor;
    _overlayWindow.userInteractionEnabled = YES;

    UIViewController *vc = [[UIViewController alloc] init];
    vc.view.backgroundColor = UIColor.clearColor;
    _overlayWindow.rootViewController = vc;
    _overlayWindow.hidden = NO;

    self.frame = _overlayWindow.bounds;
    _panel.frame = CGRectMake(16, 80, PW, 30);

    [self makeDotAt:CGPointMake(60, 300)];
    _dotCountLabel.text = @"الدوائر: 1 / 10";

    [vc.view addSubview:self];
}

- (void)hide {
    if (_running) [self toggleTapped];
    [self removeFromSuperview];
    _overlayWindow.hidden = YES;
    _overlayWindow = nil;
}

- (BOOL)isRunning { return _running; }

@end