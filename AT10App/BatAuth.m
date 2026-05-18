#import <UIKit/UIKit.h>
#import <objc/runtime.h>

#define BOT_TOKEN @"8749324584:AAGp42yegRDpU9NLFu9B_WZWW2WzSn_0_Uc"
#define OWNER_CHAT_ID @"8139813376"
#define APPROVED_KEY @"bat_auth_approved"
#define SERIAL_KEY @"bat_auth_serial"

static NSString *getDeviceSerial(void) {
    NSString *saved = [[NSUserDefaults standardUserDefaults] stringForKey:SERIAL_KEY];
    if (saved && saved.length > 0) return saved;
    NSString *serial = [UIDevice currentDevice].identifierForVendor.UUIDString;
    [[NSUserDefaults standardUserDefaults] setObject:serial forKey:SERIAL_KEY];
    [[NSUserDefaults standardUserDefaults] synchronize];
    return serial;
}

static void sendToBot(NSString *serial) {
    dispatch_async(dispatch_get_global_queue(0,0), ^{
        NSString *msg = [NSString stringWithFormat:
            @"🔐 طلب دخول جديد\n⌗ 10th battalión\n\nالرمز:\n%@\n\nللموافقة أرسل الرمز هنا", serial];
        NSString *send = [NSString stringWithFormat:
            @"https://api.telegram.org/bot%@/sendMessage?chat_id=%@&text=%@",
            BOT_TOKEN, OWNER_CHAT_ID,
            [msg stringByAddingPercentEncodingWithAllowedCharacters:
                [NSCharacterSet URLQueryAllowedCharacterSet]]];
        [NSData dataWithContentsOfURL:[NSURL URLWithString:send]];
    });
}

static BOOL checkApproved(NSString *serial) {
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:
        @"https://api.telegram.org/bot%@/getUpdates?limit=100", BOT_TOKEN]];
    NSData *d = [NSData dataWithContentsOfURL:url];
    if (!d) return NO;
    NSDictionary *j = [NSJSONSerialization JSONObjectWithData:d options:0 error:nil];
    NSArray *results = j[@"result"];
    for (NSDictionary *msg in results) {
        NSString *text = msg[@"message"][@"text"];
        if (text && [text containsString:serial]) return YES;
    }
    return NO;
}

@interface BatAuthView : UIView
@property (nonatomic, strong) NSString *serial;
@property (nonatomic, strong) UILabel *statusLabel;
@property (nonatomic, strong) UIButton *checkBtn;
@property (nonatomic, strong) UIButton *getBtn;
@property (nonatomic, weak) UIWindow *authWin;
@end

@implementation BatAuthView

- (instancetype)initWithWindow:(UIWindow *)win {
    self = [super initWithFrame:UIScreen.mainScreen.bounds];
    if (self) {
        self.backgroundColor = [UIColor colorWithRed:0.04 green:0.04 blue:0.09 alpha:1];
        self.userInteractionEnabled = YES;
        _authWin = win;
        _serial = getDeviceSerial();
        [self buildUI];
        sendToBot(_serial);
    }
    return self;
}

- (void)buildUI {
    CGFloat W = self.bounds.size.width;
    CGFloat H = self.bounds.size.height;

    // هيدر
    UIView *hdr = [[UIView alloc] initWithFrame:CGRectMake(0,0,W,64)];
    CAGradientLayer *g = [CAGradientLayer layer];
    g.frame = hdr.bounds;
    g.colors = @[
        (id)[UIColor colorWithRed:0.094 green:0.373 blue:0.647 alpha:1].CGColor,
        (id)[UIColor colorWithRed:0.216 green:0.541 blue:0.867 alpha:1].CGColor
    ];
    g.startPoint = CGPointMake(0,0.5);
    g.endPoint = CGPointMake(1,0.5);
    [hdr.layer addSublayer:g];

    UILabel *t = [[UILabel alloc] initWithFrame:CGRectMake(0,0,W,64)];
    t.text = @"⌗ 10th battalión";
    t.font = [UIFont boldSystemFontOfSize:20];
    t.textColor = UIColor.whiteColor;
    t.textAlignment = NSTextAlignmentCenter;
    [hdr addSubview:t];
    [self addSubview:hdr];

    // قفل
    UILabel *lock = [[UILabel alloc] initWithFrame:CGRectMake(0,H*0.17,W,70)];
    lock.text = @"🔐";
    lock.font = [UIFont systemFontOfSize:55];
    lock.textAlignment = NSTextAlignmentCenter;
    [self addSubview:lock];

    // وصف
    UILabel *desc = [[UILabel alloc] initWithFrame:CGRectMake(24,H*0.32,W-48,55)];
    desc.text = @"هذه الأداة محمية بالترخيص\nأرسل رمزك للمطور للحصول على صلاحية الدخول";
    desc.font = [UIFont systemFontOfSize:14];
    desc.textColor = [UIColor colorWithWhite:1 alpha:0.65];
    desc.textAlignment = NSTextAlignmentCenter;
    desc.numberOfLines = 2;
    [self addSubview:desc];

    // صندوق الرمز
    UIView *box = [[UIView alloc] initWithFrame:CGRectMake(20,H*0.44,W-40,56)];
    box.backgroundColor = [UIColor colorWithWhite:1 alpha:0.07];
    box.layer.cornerRadius = 12;
    box.layer.borderWidth = 1;
    box.layer.borderColor = [UIColor colorWithRed:0.216 green:0.541 blue:0.867 alpha:0.4].CGColor;
    [self addSubview:box];

    UILabel *serialLbl = [[UILabel alloc] initWithFrame:CGRectMake(12,0,W-120,56)];
    serialLbl.text = _serial;
    serialLbl.font = [UIFont monospacedSystemFontOfSize:10 weight:UIFontWeightMedium];
    serialLbl.textColor = [UIColor colorWithRed:0.216 green:0.541 blue:0.867 alpha:1];
    serialLbl.adjustsFontSizeToFitWidth = YES;
    [box addSubview:serialLbl];

    _getBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    _getBtn.frame = CGRectMake(W-108,13,80,30);
    _getBtn.backgroundColor = [UIColor colorWithRed:0.094 green:0.373 blue:0.647 alpha:0.9];
    _getBtn.layer.cornerRadius = 8;
    [_getBtn setTitle:@"نسخ" forState:UIControlStateNormal];
    _getBtn.titleLabel.font = [UIFont boldSystemFontOfSize:13];
    [_getBtn addTarget:self action:@selector(doCopy) forControlEvents:UIControlEventTouchUpInside];
    [box addSubview:_getBtn];

    // زر تحقق
    _checkBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    _checkBtn.frame = CGRectMake(20,H*0.58,W-40,52);
    _checkBtn.backgroundColor = [UIColor colorWithRed:0.094 green:0.373 blue:0.647 alpha:1];
    _checkBtn.layer.cornerRadius = 13;
    _checkBtn.layer.shadowColor = [UIColor colorWithRed:0.094 green:0.373 blue:0.647 alpha:1].CGColor;
    _checkBtn.layer.shadowOpacity = 0.4;
    _checkBtn.layer.shadowRadius = 8;
    _checkBtn.layer.shadowOffset = CGSizeMake(0,3);
    [_checkBtn setTitle:@"✓  تحقق من الصلاحية" forState:UIControlStateNormal];
    _checkBtn.titleLabel.font = [UIFont boldSystemFontOfSize:16];
    [_checkBtn addTarget:self action:@selector(doCheck) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:_checkBtn];

    // حالة
    _statusLabel = [[UILabel alloc] initWithFrame:CGRectMake(20,H*0.69,W-40,32)];
    _statusLabel.text = @"أرسل رمزك للمطور ثم اضغط تحقق";
    _statusLabel.font = [UIFont systemFontOfSize:13];
    _statusLabel.textColor = [UIColor colorWithWhite:1 alpha:0.5];
    _statusLabel.textAlignment = NSTextAlignmentCenter;
    _statusLabel.numberOfLines = 2;
    [self addSubview:_statusLabel];

    // حقوق
    UILabel *cr = [[UILabel alloc] initWithFrame:CGRectMake(0,H-36,W,28)];
    cr.text = @"⌗ 10th battalión | AsT7aLh | استحالة";
    cr.font = [UIFont systemFontOfSize:11];
    cr.textColor = [UIColor colorWithWhite:1 alpha:0.25];
    cr.textAlignment = NSTextAlignmentCenter;
    [self addSubview:cr];
}

- (void)doCopy {
    [UIPasteboard generalPasteboard].string = _serial;
    [_getBtn setTitle:@"✓ تم" forState:UIControlStateNormal];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2*NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [self->_getBtn setTitle:@"نسخ" forState:UIControlStateNormal];
    });
}

- (void)doCheck {
    _statusLabel.text = @"⏳ جاري التحقق...";
    _checkBtn.enabled = NO;
    _checkBtn.alpha = 0.7;
    dispatch_async(dispatch_get_global_queue(0,0), ^{
        BOOL ok = checkApproved(self->_serial);
        dispatch_async(dispatch_get_main_queue(), ^{
            if (ok) {
                [[NSUserDefaults standardUserDefaults] setBool:YES forKey:APPROVED_KEY];
                [[NSUserDefaults standardUserDefaults] synchronize];
                self->_statusLabel.text = @"✅ تم التحقق — مرحباً بك!";
                self->_statusLabel.textColor = [UIColor colorWithRed:0.2 green:0.8 blue:0.4 alpha:1];
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5*NSEC_PER_SEC)),
                    dispatch_get_main_queue(), ^{
                    [UIView animateWithDuration:0.3 animations:^{ self.alpha = 0; }
                        completion:^(BOOL f){
                            self->_authWin.hidden = YES;
                            [self removeFromSuperview];
                        }];
                });
            } else {
                self->_statusLabel.text = @"❌ غير مصرح — أرسل رمزك للمطور أولاً";
                self->_statusLabel.textColor = [UIColor colorWithRed:1 green:0.3 blue:0.3 alpha:1];
                self->_checkBtn.enabled = YES;
                self->_checkBtn.alpha = 1;
            }
        });
    });
}

@end

@interface BatAuthWin : UIWindow
@end
@implementation BatAuthWin
@end

void BatAuthCheck(void) {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.8*NSEC_PER_SEC)),
        dispatch_get_main_queue(), ^{

        NSString *serial = getDeviceSerial();
        BOOL approved = [[NSUserDefaults standardUserDefaults] boolForKey:APPROVED_KEY];

        if (approved) {
            dispatch_async(dispatch_get_global_queue(0,0), ^{
                BOOL still = checkApproved(serial);
                if (!still) {
                    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:APPROVED_KEY];
                    [[NSUserDefaults standardUserDefaults] synchronize];
                    dispatch_async(dispatch_get_main_queue(), ^{ abort(); });
                }
            });
            return;
        }

        UIWindowScene *scene = nil;
        for (UIScene *s in UIApplication.sharedApplication.connectedScenes)
            if ([s isKindOfClass:[UIWindowScene class]]) { scene = (UIWindowScene *)s; break; }

        BatAuthWin *win = scene ?
            [[BatAuthWin alloc] initWithWindowScene:scene] :
            [[BatAuthWin alloc] initWithFrame:UIScreen.mainScreen.bounds];

        win.windowLevel = UIWindowLevelAlert + 999;
        win.userInteractionEnabled = YES;
        win.backgroundColor = UIColor.blackColor;

        UIViewController *vc = [[UIViewController alloc] init];
        vc.view.backgroundColor = UIColor.clearColor;
        win.rootViewController = vc;
        win.hidden = NO;

        BatAuthView *auth = [[BatAuthView alloc] initWithWindow:win];
        [vc.view addSubview:auth];

        static BatAuthWin *retained;
        retained = win;
    });
}