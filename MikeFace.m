#import <UIKit/UIKit.h>
#import <objc/runtime.h>

static Class getMikeFaceClass(void) {
    Class cls = NSClassFromString(@"YallaLite.LTLiveMikeFace");
    if (!cls) cls = NSClassFromString(@"LTLiveMikeFace");
    return cls;
}

static UIWindow *getMainWindow(void) {
    for (UIScene *sc in UIApplication.sharedApplication.connectedScenes) {
        if (![sc isKindOfClass:[UIWindowScene class]]) continue;
        for (UIWindow *w in ((UIWindowScene *)sc).windows)
            if (w.isKeyWindow) return w;
    }
    return nil;
}

static void findAllViews(UIView *root, Class cls, NSMutableArray *result) {
    if ([root isKindOfClass:cls]) [result addObject:root];
    for (UIView *sub in root.subviews)
        findAllViews(sub, cls, result);
}

static void callDestruct(void) {
    Class cls = getMikeFaceClass();
    if (!cls) return;

    NSMutableArray *found = [NSMutableArray array];
    for (UIScene *sc in UIApplication.sharedApplication.connectedScenes) {
        if (![sc isKindOfClass:[UIWindowScene class]]) continue;
        for (UIWindow *win in ((UIWindowScene *)sc).windows)
            findAllViews(win, cls, found);
    }

    if (found.count == 0) return;

    unsigned int count = 0;
    Method *methods = class_copyMethodList(cls, &count);
    SEL cxxSel = nil;
    IMP cxxImp = nil;
    for (unsigned int i = 0; i < count; i++) {
        NSString *name = NSStringFromSelector(method_getName(methods[i]));
        if ([name containsString:@"cxx_destruct"]) {
            cxxSel = method_getName(methods[i]);
            cxxImp = method_getImplementation(methods[i]);
            break;
        }
    }
    if (methods) free(methods);

    for (UIView *v in found) {
        if (cxxImp && cxxSel)
            ((void (*)(id, SEL))cxxImp)(v, cxxSel);
    }
}

@interface MikeBtn : UIView
@property (nonatomic, strong) UIButton *mainBtn;
@property (nonatomic, assign) BOOL activated;
@end

@implementation MikeBtn

- (instancetype)init {
    self = [super initWithFrame:CGRectMake(0,0,58,58)];
    if (self) {
        self.userInteractionEnabled = YES;
        _activated = NO;

        _mainBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _mainBtn.frame = self.bounds;
        _mainBtn.backgroundColor = [UIColor colorWithRed:0.094 green:0.373 blue:0.647 alpha:0.92];
        _mainBtn.layer.cornerRadius = 29;
        _mainBtn.layer.borderWidth = 2;
        _mainBtn.layer.borderColor = [UIColor colorWithRed:0.216 green:0.541 blue:0.867 alpha:1].CGColor;
        _mainBtn.layer.masksToBounds = NO;
        _mainBtn.titleLabel.font = [UIFont boldSystemFontOfSize:7];
        _mainBtn.titleLabel.numberOfLines = 4;
        _mainBtn.titleLabel.textAlignment = NSTextAlignmentCenter;
        [_mainBtn setTitle:@"⌗ 10th\nbattalión" forState:UIControlStateNormal];
        [_mainBtn setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
        [_mainBtn addTarget:self action:@selector(tapped) forControlEvents:UIControlEventTouchUpInside];
        _mainBtn.userInteractionEnabled = YES;
        [self addSubview:_mainBtn];
    }
    return self;
}

- (void)tapped {
    _activated = !_activated;
    if (_activated) {
        [UIView animateWithDuration:0.2 animations:^{
            self->_mainBtn.backgroundColor = [UIColor colorWithWhite:0.08 alpha:0.95];
            self->_mainBtn.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.3].CGColor;
        }];
        [_mainBtn setTitle:@"⌗ 10th\nbattalión\nتراك مقلتش" forState:UIControlStateNormal];
        callDestruct();
    } else {
        [UIView animateWithDuration:0.2 animations:^{
            self->_mainBtn.backgroundColor = [UIColor colorWithRed:0.094 green:0.373 blue:0.647 alpha:0.92];
            self->_mainBtn.layer.borderColor = [UIColor colorWithRed:0.216 green:0.541 blue:0.867 alpha:1].CGColor;
        }];
        [_mainBtn setTitle:@"⌗ 10th\nbattalión" forState:UIControlStateNormal];
    }
}

@end

__attribute__((constructor))
static void MikeFaceStart(void) {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)),
        dispatch_get_main_queue(), ^{

        UIWindow *mainWin = getMainWindow();
        if (!mainWin) return;

        CGFloat screenW = mainWin.bounds.size.width;
        CGFloat screenH = mainWin.bounds.size.height;

        MikeBtn *btn = [[MikeBtn alloc] init];
        btn.center = CGPointMake(screenW - 36, screenH / 2);
        btn.hidden = YES;

        [mainWin addSubview:btn];
        [mainWin bringSubviewToFront:btn];

        [NSTimer scheduledTimerWithTimeInterval:0.5 repeats:YES block:^(NSTimer *t) {
            dispatch_async(dispatch_get_main_queue(), ^{
                UIWindow *w = getMainWindow();
                if (!w) return;

                BOOL inRoom = NO;
                UIViewController *vc = w.rootViewController;
                while (vc) {
                    NSString *name = NSStringFromClass(vc.class);
                    if ([name containsString:@"Live"] || [name containsString:@"Room"]) {
                        inRoom = YES; break;
                    }
                    if (vc.presentedViewController) vc = vc.presentedViewController;
                    else if ([vc isKindOfClass:[UINavigationController class]])
                        vc = ((UINavigationController *)vc).topViewController;
                    else if ([vc isKindOfClass:[UITabBarController class]])
                        vc = ((UITabBarController *)vc).selectedViewController;
                    else break;
                }

                btn.hidden = !inRoom;
                if (btn.superview != w) [w addSubview:btn];
                [w bringSubviewToFront:btn];
            });
        }];

        objc_setAssociatedObject(mainWin, "mike", btn, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    });
}