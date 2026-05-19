#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

static BOOL gMiniEnabled = NO;
static NSMutableDictionary<NSValue *, NSValue *> *gOriginalFrames;
static NSMutableArray<UIPanGestureRecognizer *> *gMiniPans;

static UIWindow *UnifiedMiniMainWindow(void) {
    for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
        if (![scene isKindOfClass:[UIWindowScene class]]) continue;
        for (UIWindow *w in ((UIWindowScene *)scene).windows) {
            if (!w.isHidden && w.windowLevel == UIWindowLevelNormal && w.bounds.size.width > 0 && w.bounds.size.height > 0) {
                return w;
            }
        }
    }
    return UIApplication.sharedApplication.keyWindow;
}

@interface UnifiedMiniPanTarget : NSObject
@end

@implementation UnifiedMiniPanTarget
- (void)pan:(UIPanGestureRecognizer *)g {
    UIView *v = g.view;
    if (!v) return;
    CGPoint t = [g translationInView:v.superview];
    v.center = CGPointMake(v.center.x + t.x, v.center.y + t.y);
    [g setTranslation:CGPointZero inView:v.superview];
}
@end

static UnifiedMiniPanTarget *UnifiedMiniTarget(void) {
    static UnifiedMiniPanTarget *target;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ target = [UnifiedMiniPanTarget new]; });
    return target;
}

BOOL UnifiedMiniIsEnabled(void) {
    return gMiniEnabled;
}

void UnifiedMiniToggle(void) {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *w = UnifiedMiniMainWindow();
        if (!w) return;

        if (!gOriginalFrames) gOriginalFrames = [NSMutableDictionary dictionary];
        if (!gMiniPans) gMiniPans = [NSMutableArray array];

        gMiniEnabled = !gMiniEnabled;

        if (gMiniEnabled) {
            gOriginalFrames[[NSValue valueWithNonretainedObject:w]] = [NSValue valueWithCGRect:w.frame];

            CGRect screen = UIScreen.mainScreen.bounds;
            CGFloat scale = 0.66;
            CGFloat newW = screen.size.width * scale;
            CGFloat newH = screen.size.height * scale;
            CGFloat x = (screen.size.width - newW) / 2.0;
            CGFloat y = 98.0;

            [UIView animateWithDuration:0.22 animations:^{
                w.frame = CGRectMake(x, y, newW, newH);
                w.layer.cornerRadius = 22;
                w.layer.masksToBounds = YES;
                w.layer.borderWidth = 1.2;
                w.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.25].CGColor;
                w.layer.shadowOpacity = 0.42;
                w.layer.shadowRadius = 22;
            }];

            UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:UnifiedMiniTarget() action:@selector(pan:)];
            [w addGestureRecognizer:pan];
            [gMiniPans addObject:pan];
        } else {
            NSValue *key = [NSValue valueWithNonretainedObject:w];
            CGRect original = gOriginalFrames[key] ? [gOriginalFrames[key] CGRectValue] : UIScreen.mainScreen.bounds;

            for (UIPanGestureRecognizer *pan in [gMiniPans copy]) {
                [pan.view removeGestureRecognizer:pan];
            }
            [gMiniPans removeAllObjects];

            [UIView animateWithDuration:0.22 animations:^{
                w.frame = original;
                w.layer.cornerRadius = 0;
                w.layer.masksToBounds = NO;
                w.layer.borderWidth = 0;
                w.layer.shadowOpacity = 0;
                w.layer.shadowRadius = 0;
            }];
        }
    });
}
