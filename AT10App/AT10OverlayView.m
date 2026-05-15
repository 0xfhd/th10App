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

        self.backgroundColor = UIColor.clearColor;
        self.userInteractionEnabled = YES;
        self.multipleTouchEnabled = YES;

        self.circleView = [[UIView alloc] initWithFrame:CGRectMake(150, 300, 80, 80)];
        self.circleView.backgroundColor = [[UIColor redColor] colorWithAlphaComponent:0.5];
        self.circleView.layer.cornerRadius = 40;
        self.circleView.userInteractionEnabled = YES;
        [self addSubview:self.circleView];

        UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(dragCircle:)];
        [self.circleView addGestureRecognizer:pan];
    }
    return self;
}

- (void)dragCircle:(UIPanGestureRecognizer *)gesture {
    CGPoint translation = [gesture translationInView:self];
    gesture.view.center = CGPointMake(gesture.view.center.x + translation.x,
                                      gesture.view.center.y + translation.y);
    [gesture setTranslation:CGPointZero inView:self];
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {

    if (self.hidden || self.alpha < 0.01 || !self.userInteractionEnabled)
        return [super hitTest:point withEvent:event];

    CGPoint p = [self convertPoint:point toView:self.circleView];

    if ([self.circleView pointInside:p withEvent:event])
        return self.circleView;

    return nil;
}

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    return YES;
}

@end
