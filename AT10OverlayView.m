#import "AT10OverlayView.h"

@interface AT10OverlayView ()
@property (nonatomic, strong) UIView *circleView;
@end

@implementation AT10OverlayView

+ (instancetype)sharedOverlay {
    static AT10OverlayView *shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [[self alloc] initWithFrame:[UIScreen mainScreen].bounds];
    });
    return shared;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {

        // أهم شيء: الأوفرلاي نفسه ما يستقبل لمس
        self.userInteractionEnabled = NO;
        self.exclusiveTouch = NO;
        self.multipleTouchEnabled = YES;
        self.backgroundColor = UIColor.clearColor;

        // الدائرة فقط هي اللي تستقبل لمس
        self.circleView = [[UIView alloc] initWithFrame:CGRectMake(150, 300, 80, 80)];
        self.circleView.backgroundColor = [[UIColor redColor] colorWithAlphaComponent:0.5];
        self.circleView.layer.cornerRadius = 40;
        self.circleView.userInteractionEnabled = YES; // الدائرة فقط
        [self addSubview:self.circleView];

        // سحب الدائرة
        UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(dragCircle:)];
        [self.circleView addGestureRecognizer:pan];
    }
    return self;
}

// الدائرة تتحرك فقط
- (void)dragCircle:(UIPanGestureRecognizer *)gesture {
    CGPoint translation = [gesture translationInView:self];
    gesture.view.center = CGPointMake(gesture.view.center.x + translation.x,
                                      gesture.view.center.y + translation.y);
    [gesture setTranslation:CGPointZero inView:self];
}

// أهم شيء: الأوفرلاي لا يستقبل لمس إلا على الدائرة فقط
- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    // إذا اللمس داخل الدائرة → استقبل اللمس
    if (CGRectContainsPoint(self.circleView.frame, point)) {
        return YES;
    }
    // غير كذا → مرّر اللمس للعبة
    return NO;
}

@end

