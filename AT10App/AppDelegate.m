#import "AppDelegate.h"
#import "AT10OverlayView.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

    // إنشاء النافذة الرئيسية
    self.window = [[UIWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
    self.window.backgroundColor = [UIColor colorWithRed:0.05 green:0.05 blue:0.10 alpha:1];
    
    // ViewController فارغ كخلفية
    UIViewController *root = [[UIViewController alloc] init];
    root.view.backgroundColor = [UIColor colorWithRed:0.05 green:0.05 blue:0.10 alpha:1];
    
    // إضافة شعار بسيط في المنتصف
    UILabel *logo = [[UILabel alloc] init];
    logo.text = @"⌗ 10th";
    logo.font = [UIFont boldSystemFontOfSize:28];
    logo.textColor = [UIColor colorWithRed:0.216 green:0.541 blue:0.867 alpha:1];
    logo.textAlignment = NSTextAlignmentCenter;
    logo.translatesAutoresizingMaskIntoConstraints = NO;
    [root.view addSubview:logo];
    
    UILabel *sub = [[UILabel alloc] init];
    sub.text = @"AsT7aLh | استحالة";
    sub.font = [UIFont systemFontOfSize:14];
    sub.textColor = [UIColor colorWithWhite:1 alpha:0.4];
    sub.textAlignment = NSTextAlignmentCenter;
    sub.translatesAutoresizingMaskIntoConstraints = NO;
    [root.view addSubview:sub];
    
    [NSLayoutConstraint activateConstraints:@[
        [logo.centerXAnchor constraintEqualToAnchor:root.view.centerXAnchor],
        [logo.centerYAnchor constraintEqualToAnchor:root.view.centerYAnchor constant:-15],
        [sub.centerXAnchor constraintEqualToAnchor:root.view.centerXAnchor],
        [sub.topAnchor constraintEqualToAnchor:logo.bottomAnchor constant:8],
    ]];
    
    self.window.rootViewController = root;
    [self.window makeKeyAndVisible];
    
    // تشغيل الـ Overlay فوراً بعد ما تفتح النافذة
    dispatch_async(dispatch_get_main_queue(), ^{
        [[AT10OverlayView sharedOverlay] showInView:root.view];
    });
    
    return YES;
}

@end
