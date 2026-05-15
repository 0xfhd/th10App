#import "AT10OverlayView.h"
#import <QuartzCore/QuartzCore.h>

#define BLUE_DARK  [UIColor colorWithRed:0.094 green:0.373 blue:0.647 alpha:1]
#define BLUE_MID   [UIColor colorWithRed:0.216 green:0.541 blue:0.867 alpha:1]
#define BLUE_LIGHT [UIColor colorWithRed:0.902 green:0.945 blue:0.984 alpha:1]
#define BLACK_BTN  [UIColor colorWithRed:0.07 green:0.07 blue:0.07 alpha:1]

@interface AT10OverlayView()
@property (nonatomic,strong) UIView        *dot;
@property (nonatomic,strong) UILabel       *dotLabel;
@property (nonatomic,strong) UIView        *panel;
@property (nonatomic,strong) UIButton      *toggleBtn;
@property (nonatomic,strong) UISlider      *speedSlider;
@property (nonatomic,strong) UILabel       *cpsLabel;
@property (nonatomic,strong) UILabel       *cntLabel;
@property (nonatomic,strong) UILabel       *speedValLabel;
@property (nonatomic,strong) UIView        *panelBody;
@property (nonatomic,strong) UIButton      *collapseBtn;
@property (nonatomic,assign) BOOL          collapsed;
@property (nonatomic,assign) BOOL          running;
@property (nonatomic,assign) CGPoint       dotPos;
@property (nonatomic,assign) long          clicks;
@property (nonatomic,assign) NSInteger     cps;
@property (nonatomic,strong) CADisplayLink *ticker;
@property (nonatomic,assign) NSTimeInterval accumulator;
@property (nonatomic,assign) long          lastClicks;
@property (nonatomic,assign) NSTimeInterval lastCPSTime;
@end

@implementation AT10OverlayView

+ (instancetype)sharedOverlay {
    static AT10OverlayView *i;
    static dispatch_once_t t;
    dispatch_once(&t, ^{ i = [[self alloc] initWithFrame:CGRectZero]; });
    return i;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = UIColor.clearColor;
        self.userInteractionEnabled = YES;
        self.multipleTouchEnabled = YES;
        self.exclusiveTouch = NO;

        _cps = 120;
        _credit = @"⌗ 10th | AsT7aLh | استحالة";

        [self buildDot];
        [self buildPanel];
    }
    return self;
}

#pragma mark - الدائرة

- (void)buildDot {
    _dot = [[UIView alloc] initWithFrame:CGRectMake(0,0,46,46)];
    _dot.backgroundColor = UIColor.whiteColor;
    _dot.layer.cornerRadius = 23;
    _dot.layer.borderWidth = 2.5;
    _dot.layer.borderColor = BLUE_MID.CGColor;
    _dot.layer.shadowColor  = BLUE_MID.CGColor;
    _dot.layer.shadowOpacity = 0.25;
    _dot.layer.shadowRadius  = 6;
    _dot.layer.shadowOffset  = CGSizeMake(0,2);
    _dot.layer.masksToBounds = NO;

    _dotLabel = [[UILabel alloc] initWithFrame:_dot.bounds];
    _dotLabel.text = @"⌗ 10th";
    _dotLabel.font = [UIFont boldSystemFontOfSize:7.5];
    _dotLabel.textColor = BLUE_DARK;
    _dotLabel.textAlignment = NSTextAlignmentCenter;
    _dotLabel.numberOfLines = 2;
    [_dot addSubview:_dotLabel];

    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc]
        initWithTarget:self action:@selector(handleDotPan:)];
    [_dot addGestureRecognizer:pan];
    [self addSubview:_dot];
}

- (void)handleDotPan:(UIPanGestureRecognizer *)g {
    if (_running) return;
    CGPoint t = [g translationInView:self];
    _dot.center = CGPointMake(
        MAX(23, MIN(self.bounds.size.width-23,  _dot.center.x + t.x)),
        MAX(23, MIN(self.bounds.size.height-23, _dot.center.y + t.y))
    );
    _dotPos = _dot.center;
    [g setTranslation:CGPointZero inView:self];
}

#pragma mark - القائمة

- (void)buildPanel {
    _panel = [[UIView alloc] initWithFrame:CGRectMake(16,80,210,0)];
    _panel.backgroundColor = UIColor.whiteColor;
    _panel.layer.cornerRadius = 14;
    _panel.layer.borderWidth  = 1.5;
    _panel.layer.borderColor  = [UIColor colorWithRed:0.76 green:0.85 blue:0.97 alpha:1].CGColor;
    _panel.layer.shadowColor  = BLUE_DARK.CGColor;
    _panel.layer.shadowOpacity= 0.10;
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
    [_collapseBtn setTitle:@"▲" forState:UIControlStateNormal];
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
    [_panel addSubview:_panelBody];

    int y = 10;

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

    UILabel *spdTitle = [self lbl:@"السرعة" x:10 y:y w:100 bold:YES small:YES];
    spdTitle.textColor = [UIColor colorWithRed:0.48 green:0.70 blue:0.88 alpha:1];
    [_panelBody addSubview:spdTitle];

    _speedValLabel = [self lbl:@"أقصى سرعة" x:110 y:y w:90 bold:YES small:YES];
    _speedValLabel.textAlignment = NSTextAlignmentRight;
    _speedValLabel.textColor = BLUE_DARK;
    [_panelBody addSubview:_speedValLabel];
    y += 18;

    _speedSlider = [[UISlider alloc] initWithFrame:CGRectMake(10,y,190,28)];
    _speedSlider.minimumValue = 1;
    _speedSlider.maximumValue = 120;
    _speedSlider.value = 120;
    _speedSlider.tintColor = BLUE_DARK;
    [_speedSlider addTarget:self action:@selector(speedChanged)
          forControlEvents:UIControlEventValueChanged];
    [_panelBody addSubview:_speedSlider];

    UILabel *slow = [self lbl:@"أبطأ" x:10 y:y+28 w:40 bold:NO small:YES];
    slow.textColor = [UIColor colorWithRed:0.66 green:0.78 blue:0.93 alpha:1];
    UILabel *fast = [self lbl:@"أسرع" x:160 y:y+28 w:40 bold:NO small:YES];
    fast.textColor = slow.textColor;
    fast.textAlignment = NSTextAlignmentRight;
    [_panelBody addSubview:slow];
    [_panelBody addSubview:fast];
    y += 48;

    UIView *row1 = [self makeStatRow:@"السرعة الفعلية:" val:@"—" x:10 y:y];
    _cpsLabel = (UILabel *)[row1 viewWithTag:99];
    [_panelBody addSubview:row1];
    y += 26;

    UIView *row2 = [self makeStatRow:@"النقرات:" val:@"0" x:10 y:y];
    _cntLabel = (UILabel *)[row2 viewWithTag:99];
    [_panelBody addSubview:row2];
    y += 26;

    UILabel *cr = [self lbl:@"⌗ 10th | AsT7aLh | استحالة" x:10 y:y w:190 bold:NO small:YES];
    cr.textAlignment = NSTextAlignmentCenter;
    cr.textColor = [UIColor colorWithRed:0.66 green:0.78 blue:0.93 alpha:1];
    cr.backgroundColor = [UIColor colorWithRed:0.94 green:0.97 blue:1.0 alpha:1];
    cr.layer.cornerRadius = 6;
    cr.layer.masksToBounds = YES;
    [_panelBody addSubview:cr];
    y += 22;

    _panelBody.frame = CGRectMake(0,36,210,y+10);
    _panel.frame = CGRectMake(16,80,210,36+y+10);
    [self addSubview:_panel];
}

- (UIView *)makeStatRow:(NSString *)title val:(NSString *)val x:(int)x y:(int)y {
    UIView *row = [[UIView alloc] initWithFrame:CGRectMake(x,y,190,22)];
    row.backgroundColor = [UIColor colorWithRed:0.94 green:0.97 blue:1.0 alpha:1];
    row.layer.cornerRadius = 6;
    row.clipsToBounds = YES;

    UILabel *tl = [[UILabel alloc] initWithFrame:CGRectMake(8,2,100,18)];
    tl.text = title;
    tl.font = [UIFont systemFontOfSize:9.5];
    tl.textColor = BLUE_DARK;
    [row addSubview:tl];

    UILabel *vl = [[UILabel alloc] initWithFrame:CGRectMake(100,2,82,18)];
    vl.text = val;
    vl.font = [UIFont boldSystemFontOfSize:10];
    vl.textColor = BLUE_DARK;
    vl.textAlignment = NSTextAlignmentRight;
    vl.tag = 99;
    [row addSubview:vl];

    return row;
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
    _toggleBtn.layer.shadowColor   = BLUE_DARK.CGColor;
    _toggleBtn.layer.shadowOpacity = 0.30;
    _toggleBtn.layer.shadowRadius  = 6;
    _toggleBtn.layer.shadowOffset  = CGSizeMake(0,2);
}

- (void)setButtonBlack {
    for (CALayer *l in _toggleBtn.layer.sublayers)
        if ([l isKindOfClass:[CAGradientLayer class]]) { [l removeFromSuperlayer]; break; }
    _toggleBtn.backgroundColor    = BLACK_BTN;
    _toggleBtn.layer.shadowColor   = UIColor.blackColor.CGColor;
    _toggleBtn.layer.shadowOpacity = 0.30;
    _toggleBtn.layer.shadowRadius  = 6;
    _toggleBtn.layer.shadowOffset  = CGSizeMake(0,2);
}

- (UILabel *)lbl:(NSString *)t x:(int)x y:(int)y w:(int)w bold:(BOOL)b small:(BOOL)s {
    UILabel *l = [[UILabel alloc] initWithFrame:CGRectMake(x,y,w,18)];
    l.text = t;
    l.textColor = BLUE_DARK;
    l.font = b ? [UIFont boldSystemFontOfSize:s?9.5:11] : [UIFont systemFontOfSize:s?9:10];
    return l;
}

- (void)handlePanelPan:(UIPanGestureRecognizer *)g {
    CGPoint t = [g translationInView:self];
    _panel.center = CGPointMake(
        MAX(_panel.bounds.size.width/2,  MIN(self.bounds.size.width  - _panel.bounds.size.width/2,  _panel.center.x + t.x)),
        MAX(_panel.bounds.size.height/2, MIN(self.bounds.size.height - _panel.bounds.size.height/2, _panel.center.y + t.y))
    );
    [g setTranslation:CGPointZero inView:self];
}

- (void)toggleCollapse {
    _collapsed = !_collapsed;
    [UIView animateWithDuration:0.25 animations:^{
        self->_panelBody.alpha = self->_collapsed ? 0 : 1;
        CGRect f = self->_panel.frame;
        f.size.height = self->_collapsed ? 36 : 36 + self->_panelBody.bounds.size.height;
        self->_panel.frame = f;
    }];
    [_collapseBtn setTitle:_collapsed ? @"▼" : @"▲" forState:UIControlStateNormal];
}

#pragma mark - التشغيل

- (void)speedChanged {
    int v = (int)_speedSlider.value;
    _cps = v;
    _speedValLabel.text = v >= 120 ? @"أقصى سرعة" : [NSString stringWithFormat:@"%d ن/ث", v];
}

- (void)toggleTapped {
    if (!_running) {
        _running = YES;
        _accumulator = 0;
        _lastClicks = _clicks;
        _lastCPSTime = CACurrentMediaTime();
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
        _cpsLabel.text = @"—";
    }
}

- (void)tick:(CADisplayLink *)dl {
    if (!_running) return;
    _accumulator += dl.duration;
    double interval = 1.0 / MAX(1, _cps);
    while (_accumulator >= interval) {
        _accumulator -= interval;
        _clicks++;
        if (self.onTap) self.onTap(_dotPos);
        dispatch_async(dispatch_get_main_queue(), ^{
            self->_dot.backgroundColor = [UIColor colorWithRed:0.84 green:0.91 blue:0.97 alpha:1];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 40*NSEC_PER_MSEC), dispatch_get_main_queue(), ^{
                self->_dot.backgroundColor = UIColor.whiteColor;
            });
        });
    }
    NSTimeInterval now = CACurrentMediaTime();
    if (now - _lastCPSTime >= 1.0) {
        long diff = _clicks - _lastClicks;
        _lastClicks = _clicks;
        _lastCPSTime = now;
        dispatch_async(dispatch_get_main_queue(), ^{
            self->_cpsLabel.text = [NSString stringWithFormat:@"%ld ن/ث", diff];
            self->_cntLabel.text = [NSString stringWithFormat:@"%ld", self->_clicks];
        });
    }
}

#pragma mark - عرض وإخفاء

- (void)showInView:(UIView *)parentView {
    self.frame = parentView.bounds;
    _dotPos = CGPointMake(parentView.bounds.size.width/2, parentView.bounds.size.height/2);
    _dot.center = _dotPos;
    [parentView addSubview:self];
}

- (void)hide {
    if (_running) [self toggleTapped];
    [self removeFromSuperview];
}

- (BOOL)isRunning      { return _running; }
- (CGPoint)dotPosition { return _dotPos; }
- (long)totalClicks    { return _clicks; }

#pragma mark - إصلاح اللمسات (الأهم)

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {

    CGPoint p = [
    [self convertPoint:point toView:self];

    // لو اللمس على الدائرة
    if (CGRectContainsPoint(self.dot.frame, p)) {
        return YES;
    }

    // لو اللمس على اللوحة
    if (CGRectContainsPoint(self.panel.frame, p)) {
        return YES;
    }

    // أي مكان ثاني → مرر اللمس للعبة
    return NO;
}
@end
