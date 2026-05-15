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

        // الأوفرلاي نفسه شفاف ويستقبل لمس فقط عشان نتحكم فيه
        self.backgroundColor = UIColor.clearColor;
        self.userInteractionEnabled = YES;
        self.multipleTouchEnabled = YES;
        self.exclusiveTouch = NO;

        // الدائرة اللي نبيها تتفاعل
        self.circleView = [[UIView alloc] initWithFrame:CGRectMake(150, 300, 80, 80)];
        self.circleView.backgroundColor = [[UIColor redColor] colorWithAlphaComponent:0.5];
        self.circleView.layer.cornerRadius = 40;
        self.circleView.userInteractionEnabled = YES;
        [self addSubview:self.circleView];

        // سحب الدائرة
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

// هنا السحر الحقيقي
// نسمح باللمس فقط على الدائرة، والباقي يروح للعبة
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {

    // لو الأوفرلاي مخفي أو شفاف جدًا → لا شيء
    if (self.hidden || self.alpha < 0.01 || !self.userInteractionEnabled) {
        return [super hitTest:point withEvent:event];
    }

    // نحول النقطة لإحداثيات الدائرة
    CGPoint pointInCircle = [self convertPoint:point toView:self.circleView];

    // إذا اللمس داخل الدائرة → رجّع الدائرة (تستقبل اللمس)
    if ([self.circleView pointInside:pointInCircle withEvent:event]) {
        return self.circleView;
    }

    // غير كذا → رجّع nil عشان اللمس يروح للعبة تحت
    return nil;
}

// نخلي pointInside يرجع YES عشان hitTest يشتغل
- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    return YES;
}

@end
