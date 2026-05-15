#import "AT10OverlayView.h"
#import <QuartzCore/QuartzCore.h>

#define BLUE_DARK  [UIColor colorWithRed:0.094 green:0.373 blue:0.647 alpha:1]
#define BLUE_MID   [UIColor colorWithRed:0.216 green:0.541 blue:0.867 alpha:1]
#define BLACK_BTN  [UIColor colorWithRed:0.07 green:0.07 blue:0.07 alpha:1]
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

#pragma mark - الدائرة

- (AT10Dot *)makeDotAt:(CGPoint)center {
    AT10Dot *dot = [[AT10Dot alloc] initWithFrame:CGRectMake(0,0,46,46)];
    dot.backgroundColor = [UIColor colorWithWhite:1 alpha:0.15];
    dot.layer.cornerRadius = 23;
    dot.layer.borderWidth = 2;
    dot.layer.borderColor = [UIColor colorWithRed:0.216 green:0.541 blue:0.867 alpha:0.6].CGColor;
    dot.layer.masksToBounds = YES;
    dot.dotPos = center;

    UILabel *lbl = [[UILabel alloc] initWithFrame:dot.bounds];
    lbl.text = @"⌗ 10th";
    lbl.font = [UIFont boldSystemFontOfSize:7.5];
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
    if (_running) return; // مقفل أثناء التشغيل
    AT10Dot *dot = (AT10Dot *)g.view;
    CGPoint t = [g translationInView:self];
    dot.center = CGPointMake(
        MAX(23, MIN(self.bounds.size.width-23,  dot.center.x + t.x)),
        MAX(23, MIN(self.bounds.size.height-23, dot.center.y + t.y))
    );
    dot.dotPos = dot.center;
    [g setTranslation:CGPointZero inView:self];
}

- (void)dotTapped {
    [self toggleCollapse];
}

#pragma mark - القائمة

- (void)buildPanel {
    _panel = [[UIView alloc] initWithFrame:CGRectMake(16,80,210,36)];
    _panel.alpha = 0;
    _panel.backgroundColor = [UIColor colorWithWhite:0 alpha:0.7];
    _panel.layer.cornerRadius = 14;
    _panel.layer.borderWidth  = 1.5;
    _panel.layer.borderColor  = [UIColor colorWithWhite:1 alpha:0.15].CGColor;
    _panel.layer.shadowColor  = UIColor.blackColor.CGColor;
    _panel.layer.shadowOpacity= 0.3;
    _panel.layer.shadowRadius = 10;
    _panel.layer.shadowOffset = CGSizeMake(0,3);
    _panel.clipsToBounds = YES;

    UIView *hdr = [[UIView alloc] initWithFrame:CGRectMake(0,0,210,36)];
    CAGradientLayer *g = [CAGradientLayer layer];
    g.frame = hdr.bounds;
    g.colors = @[(id)BLUE_DARK.CGColor, (id)BLUE_MID.CGColor];
    g.startPoint = CGPointMake(0,0.5);
    g.endPoint   = CGPointMake(1,0.5);
    [hdr.layer addSublayer:g];

    UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(10,0,155,36)];
    title.text = @"⌗ 10th — AsT7aLh";
    title.font = [UIFont boldSystemFontOfSize:10.5];
    title.textColor = UIColor.whiteColor;
    [hdr addSubview:title];

    _collapseBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    _collapseBtn.frame = CGRectMake(174,6,24,24);
    _collapseBtn.backgroundColor = [UIColor colorWithWhite:1 alpha:0.18];
    _collapseBtn.layer.cornerRadius = 6;
    [_collapseBtn setTitle:@"▼" forState:UIControlStateNormal];
    _collapseBtn.titleLabel.font = [UIFont systemFontOfSize:11];
    [_collapseBtn addTarget:self action:@selector(toggleCollapse)
          forControlEvents:UIControlEventTouchUpInside];
    [hdr addSubview:_collapseBtn];

    UIPanGestureRecognizer *panG = [[UIPanGestureRecognizer alloc]
        initWithTarget:self action:@selector(handlePanelPan:)];
    [hdr addGestureRecognizer:panG];
    [_panel addSubview:hdr];

    _panelBody = [[UIView alloc] initWithFrame:CGRectMake(0,36,210,240)];
    _panelBody.backgroundColor = UIColor.clearColor;
    _panelBody.alpha = 0;
    [_panel addSubview:_panelBody];

    int y = 10;

    // زر التفعيل
    _toggleBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    _toggleBtn.frame = CGRectMake(10,y,190,38);
    _toggleBtn.layer.cornerRadius = 9;
    _toggleBtn.titleLabel.font = [UIFont boldSystemFontOfSize:14];
    [_toggleBtn setTitle:@"▶  تفعيل" forState:UIControlStateNormal];
    [_toggleBtn setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    [self setButtonBlue];
    [_toggleBtn addTarget:self action:@selector(toggleTapped)
        forControlEvents:UIControlEventTouchUpInside];
    [_panelBody addSubview:_toggleBtn];
    y += 48;

    // السرعة
    UILabel *spdTitle = [self lbl:@"السرعة" x:10 y:y w:100 bold:YES small:YES];
    spdTitle.textColor = [UIColor colorWithWhite:1 alpha:0.7];
    [_panelBody addSubview:spdTitle];

    _speedValLabel = [self lbl:@"متوسط" x:110 y:y w:90 bold:YES small:YES];
    _speedValLabel.textAlignment = NSTextAlignmentRight;
    _speedValLabel.textColor = UIColor.whiteColor;
    [_panelBody addSubview:_speedValLabel];
    y += 18;

    _speedSlider = [[UISlider alloc] initWithFrame:CGRectMake(10,y,190,28)];
    _speedSlider.minimumValue = 1;
    _speedSlider.maximumValue = 60;
    _speedSlider.value = 30;
    _speedSlider.tintColor = BLUE_MID;
    [_speedSlider addTarget:self action:@selector(speedChanged)
          forControlEvents:UIControlEventValueChanged];
    [_panelBody addSubview:_speedSlider];

    UILabel *slow = [self lbl:@"أسرع" x:10 y:y+28 w:40 bold:NO small:YES];
    slow.textColor = [UIColor colorWithWhite:1 alpha:0.5];
    UILabel *fast = [self lbl:@"أبطأ" x:160 y:y+28 w:40 bold:NO small:YES];
    fast.textColor = slow.textColor;
    fast.textAlignment = NSTextAlignmentRight;
    [_panelBody addSubview:slow];
    [_panelBody addSubview:fast];
    y += 48;

    // زر إضافة دائرة
    UIButton *addDot = [UIButton buttonWithType:UIButtonTypeCustom];
    addDot.frame = CGRectMake(10,y,190,34);
    addDot.layer.cornerRadius = 8;
    addDot.backgroundColor = [UIColor colorWithWhite:1 alpha:0.12];
    addDot.layer.borderWidth = 1;
    addDot.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.2].CGColor;
    addDot.titleLabel.font = [UIFont boldSystemFontOfSize:12];
    [addDot setTitle:@"＋  إضافة دائرة" forState:UIControlStateNormal];
    [addDot setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    [addDot addTarget:self action:@selector(addDotTapped)
        forControlEvents:UIControlEventTouchUpInside];
    [_panelBody addSubview:addDot];
    y += 42;

    // عداد الدوائر
    _dotCountLabel = [self lbl:@"الدوائر: 0 / 10" x:10 y:y w:190 bold:NO small:YES];
    _dotCountLabel.textAlignment = NSTextAlignmentCenter;
    _dotCountLabel.textColor = [UIColor colorWithWhite:1 alpha:0.5];
    [_panelBody addSubview:_dotCountLabel];
    y += 22;

    // الحقوق
    UILabel *cr = [self lbl:@"⌗ 10th | AsT7aLh | استحالة" x:10 y:y w:190 bold:NO small:YES];
    cr.textAlignment = NSTextAlignmentCenter;
    cr.textColor = [UIColor colorWithWhite:1 alpha:0.6];
    cr.backgroundColor = [UIColor colorWithWhite:0 alpha:0.3];
    cr.layer.cornerRadius = 6;
    cr.layer.masksToBounds = YES;
    [_panelBody addSubview:cr];
    y += 22;

    _panelBody.frame = CGRectMake(0,36,210,y+10);
    [self addSubview:_panel];
}

- (void)addDotTapped {
    if (_dots.count >= MAX_DOTS) return;
    CGPoint center = CGPointMake(self.bounds.size.width/2 + (_dots.count * 10),
                                  self.bounds.size.height/2);
    [self makeDotAt:center];
    _dotCountLabel.text = [NSString stringWithFormat:@"الدوائر: %lu / 10", (unsigned long)_dots.count];
}

- (void)toggleCollapse {
    _collapsed = !_collapsed;
    [UIView animateWithDuration:0.25 animations:^{
        self->_panelBody.alpha = self->_collapsed ? 0 : 1;
        CGRect f = self->_panel.frame;
        f.size.height = self->_collapsed ? 36 : 36 + self->_panelBody.bounds.size.height;
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
    g.cornerRadius = 9;
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

- (UILabel *)lbl:(NSString *)t x:(int)x y:(int)y w:(int)w bold:(BOOL)b small:(BOOL)s {
    UILabel *l = [[UILabel alloc] initWithFrame:CGRectMake(x,y,w,18)];
    l.text = t;
    l.textColor = UIColor.whiteColor;
    l.font = b ? [UIFont boldSystemFontOfSize:s?9.5:11] : [UIFont systemFontOfSize:s?9:10];
    return l;
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
    if (v <= 10) _speedValLabel.text = @"بطيء";
    else if (v <= 30) _speedValLabel.text = @"متوسط";
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
    _panel.frame = CGRectMake(16, 80, 210, 36);

    // دائرة أولى تلقائياً
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