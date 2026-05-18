#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <CommonCrypto/CommonDigest.h>

#define BOT_TOKEN @"8749324584:AAGp42yegRDpU9NLFu9B_WZWW2WzSn_0_Uc"
#define OWNER_CHAT_ID @"8139813376"
#define APPROVED_KEY @"bat_auth_approved"
#define SERIAL_KEY @"bat_auth_serial"

// نولد رمز خاص من الـ dylib
static NSString *generateCustomSerial(void) {
    NSString *saved = [[NSUserDefaults standardUserDefaults] stringForKey:SERIAL_KEY];
    if (saved && saved.length > 0) return saved;

    // نولد رمز فريد من UUID + وقت
    NSString *raw = [NSString stringWithFormat:@"%@-%f",
        [UIDevice currentDevice].identifierForVendor.UUIDString,
        [[NSDate date] timeIntervalSince1970]];

    // نحول لـ MD5
    const char *cStr = raw.UTF8String;
    unsigned char r[CC_MD5_DIGEST_LENGTH];
    CC_MD5(cStr, (CC_LONG)strlen(cStr), r);

    // نأخذ أول 16 حرف ونقسمهم بشكل جميل
    NSString *hash = [NSString stringWithFormat:@"%02X%02X%02X%02X%02X%02X%02X%02X",
        r[0],r[1],r[2],r[3],r[4],r[5],r[6],r[7]];

    // نشكله XXXX-XXXX-XXXX
    NSString *serial = [NSString stringWithFormat:@"%@-%@-%@",
        [hash substringWithRange:NSMakeRange(0,4)],
        [hash substringWithRange:NSMakeRange(4,4)],
        [hash substringWithRange:NSMakeRange(8,4)]];

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

// ===== تأثير النجوم =====
@interface StarLayer : CAEmitterLayer
@end
@implementation StarLayer
+ (instancetype)starLayerWithFrame:(CGRect)frame {
    StarLayer *layer = [StarLayer layer];
    layer.frame = frame;
    layer.emitterPosition = CGPointMake(frame.size.width/2, -10);
    layer.emitterSize = CGSizeMake(frame.size.width, 0);
    layer.emitterShape = kCAEmitterLayerLine;
    layer.renderMode = kCAEmitterLayerAdditive;

    CAEmitterCell *cell = [CAEmitterCell emitterCell];
    cell.name = @"star";
    cell.birthRate = 3;
    cell.lifetime = 8;
    cell.velocity = 60;
    cell.velocityRange = 40;
    cell.emissionLongitude = M_PI;
    cell.emissionRange = M_PI/8;
    cell.scale = 0.3;
    cell.scaleRange = 0.2;
    cell.alphaSpeed = -0.1;
    cell.color = [UIColor colorWithRed:0.216 green:0.541 blue:0.867 alpha:0.8].CGColor;

    // نسوي نجمة صغيرة
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(8,8), NO, 0);
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(ctx, [UIColor whiteColor].CGColor);
    CGContextFillEllipseInRect(ctx, CGRectMake(0,0,8,8));
    UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    cell.contents = (id)img.CGImage;

    layer.emitterCells = @[cell];
    return layer;
}
@end

// ===== واجهة التحقق =====
@interface BatAuthView : UIView
@property (nonatomic, strong) NSString *serial;
@property (nonatomic, strong) UILabel *statusLabel;
@property (nonatomic, strong) UIButton *checkBtn;
@property (nonatomic, strong) UIButton *getBtn;
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, weak) UIWindow *authWin;
@end

@implementation BatAuthView

- (instancetype)initWithWindow:(UIWindow *)win {
    self = [super initWithFrame:UIScreen.mainScreen.bounds];
    if (self) {
        self.backgroundColor = [UIColor colorWithRed:0.03 green:0.03 blue:0.08 alpha:1];
        self.userInteractionEnabled = YES;
        _authWin = win;
        _serial = generateCustomSerial();
        [self buildUI];
        [self addStars];
        sendToBot(_serial);
    }
    return self;
}

- (void)addStars {
    StarLayer *stars = [StarLayer starLayerWithFrame:self.bounds];
    [self.layer insertSublayer:stars atIndex:0];
}

- (void)buildUI {
    CGFloat W = self.bounds.size.width;
    CGFloat H = self.bounds.size.height;

    // هيدر متدرج
    UIView *hdr = [[UIView alloc] initWithFrame:CGRectMake(0,0,W,70)];
    CAGradientLayer *g = [CAGradientLayer layer];
    g.frame = hdr.bounds;
    g.colors = @[
        (id)[UIColor colorWithRed:0.094 green:0.373 blue:0.647 alpha:1].CGColor,
        (id)[UIColor colorWithRed:0.04 green:0.04 blue:0.09 alpha:0].CGColor
    ];
    g.startPoint = CGPointMake(0.5,0);
    g.endPoint = CGPointMake(0.5,1);
    [hdr.layer addSublayer:g];

    UILabel *t = [[UILabel alloc] initWithFrame:CGRectMake(0,10,W,50)];
    t.text = @"⌗ 10th battalión";
    t.font = [UIFont boldSystemFontOfSize:22];
    t.textColor = UIColor.whiteColor;
    t.textAlignment = NSTextAlignmentCenter;
    [hdr addSubview:t];
    [self addSubview:hdr];

    // اسم صاحب الأداة مع تأثير
    _nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(0,H*0.15,W,60)];
    _nameLabel.text = @"⌗ AsT7aLlllh";
    _nameLabel.font = [UIFont boldSystemFontOfSize:32];
    _nameLabel.textColor = [UIColor colorWithRed:0.216 green:0.541 blue:0.867 alpha:1];
    _nameLabel.textAlignment = NSTextAlignmentCenter;
    _nameLabel.alpha = 0;
    [self addSubview:_nameLabel];

    // تأثير ظهور الاسم
    [UIView animateWithDuration:1.5 delay:0.3
        options:UIViewAnimationOptionCurveEaseInOut
        animations:^{ self->_nameLabel.alpha = 1; }
        completion:nil];

    // تأثير نبض على الاسم
    CABasicAnimation *pulse = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
    pulse.fromValue = @(1.0);
    pulse.toValue = @(1.05);
    pulse.duration = 1.5;
    pulse.autoreverses = YES;
    pulse.repeatCount = HUGE_VALF;
    [_nameLabel.layer addAnimation:pulse forKey:@"pulse"];

    // خط فاصل مضيء
    UIView *line = [[UIView alloc] initWithFrame:CGRectMake(W*0.2, H*0.27, W*0.6, 1)];
    line.backgroundColor = [UIColor colorWithRed:0.216 green:0.541 blue:0.867 alpha:0.3];
    [self addSubview:line];

    // وصف
    UILabel *desc = [[UILabel alloc] initWithFrame:CGRectMake(24,H*0.3,W-48,50)];
    desc.text = @"هذه الأداة محمية بالترخيص\nأرسل رمزك للمطور للحصول على صلاحية الدخول";
    desc.font = [UIFont systemFontOfSize:13];
    desc.textColor = [UIColor colorWithWhite:1 alpha:0.55];
    desc.textAlignment = NSTextAlignmentCenter;
    desc.numberOfLines = 2;
    [self addSubview:desc];

    // صندوق الرمز
    UIView *box = [[UIView alloc] initWithFrame:CGRectMake(20,H*0.42,W-40,56)];
    box.backgroundColor = [UIColor colorWithWhite:1 alpha:0.06];
    box.layer.cornerRadius = 12;
    box.layer.borderWidth = 1;
    box.layer.borderColor = [UIColor colorWithRed:0.216 green:0.541 blue:0.867 alpha:0.35].CGColor;

    // تأثير توهج على الصندوق
    box.layer.shadowColor = [UIColor colorWithRed:0.216 green:0.541 blue:0.867 alpha:1].CGColor;
    box.layer.shadowOpacity = 0.3;
    box.layer.shadowRadius = 8;
    box.layer.shadowOffset = CGSizeZero;
    [self addSubview:box];

    UILabel *serialLbl = [[UILabel alloc] initWithFrame:CGRectMake(12,0,W-120,56)];
    serialLbl.text = _serial;
    serialLbl.font = [UIFont monospacedSystemFontOfSize:16 weight:UIFontWeightBold];
    serialLbl.textColor = [UIColor colorWithRed:0.216 green:0.541 blue:0.867 alpha:1];
    serialLbl.textAlignment = NSTextAlignmentCenter;
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
    _checkBtn.frame = CGRectMake(20,H*0.56,W-40,52);
    _checkBtn.layer.cornerRadius = 13;
    _checkBtn.titleLabel.font = [UIFont boldSystemFontOfSize:16];
    [_checkBtn setTitle:@"✓  تحقق من الصلاحية" forState:UIControlStateNormal];
    [_checkBtn setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];

    CAGradientLayer *btnG = [CAGradientLayer layer];
    btnG.frame = CGRectMake(0,0,W-40,52);
    btnG.cornerRadius = 13;
    btnG.colors = @[
        (id)[UIColor colorWithRed:0.094 green:0.373 blue:0.647 alpha:1].CGColor,
        (id)[UIColor colorWithRed:0.216 green:0.541 blue:0.867 alpha:1].CGColor
    ];
    btnG.startPoint = CGPointMake(0,0.5);
    btnG.endPoint = CGPointMake(1,0.5);
    [_checkBtn.layer insertSublayer:btnG atIndex:0];
    _checkBtn.layer.shadowColor = [UIColor colorWithRed:0.094 green:0.373 blue:0.647 alpha:1].CGColor;
    _checkBtn.layer.shadowOpacity = 0.5;
    _checkBtn.layer.shadowRadius = 10;
    _checkBtn.layer.shadowOffset = CGSizeMake(0,4);

    [_checkBtn addTarget:self action:@selector(doCheck) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:_checkBtn];

    // حالة
    _statusLabel = [[UILabel alloc] initWithFrame:CGRectMake(20,H*0.68,W-40,36)];
    _statusLabel.text = @"أرسل رمزك للمطور ثم اضغط تحقق";
    _statusLabel.font = [UIFont systemFontOfSize:13];
    _statusLabel.textColor = [UIColor colorWithWhite:1 alpha:0.45];
    _statusLabel.textAlignment = NSTextAlignmentCenter;
    _statusLabel.numberOfLines = 2;
    [self addSubview:_statusLabel];

    // حقوق
    UILabel *cr = [[UILabel alloc] initWithFrame:CGRectMake(0,H-36,W,28)];
    cr.text = @"⌗ 10th battalión | AsT7aLh | استحالة";
    cr.font = [UIFont systemFontOfSize:11];
    cr.textColor = [UIColor colorWithWhite:1 alpha:0.2];
    cr.textAlignment = NSTextAlignmentCenter;
    [self addSubview:cr];
}

- (void)doCopy {
    [UIPasteboard generalPasteboard].string = _serial;
    [_getBtn setTitle:@"✓ تم" forState:UIControlStateNormal];
    _getBtn.backgroundColor = [UIColor colorWithRed:0.1 green:0.6 blue:0.3 alpha:0.9];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2*NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [self->_getBtn setTitle:@"نسخ" forState:UIControlStateNormal];
        self->_getBtn.backgroundColor = [UIColor colorWithRed:0.094 green:0.373 blue:0.647 alpha:0.9];
    });
}

- (void)doCheck {
    _statusLabel.text = @"⏳ جاري التحقق...";
    _statusLabel.textColor = [UIColor colorWithWhite:1 alpha:0.6];
    _checkBtn.enabled = NO;
    _checkBtn.alpha = 0.7;

    dispatch_async(dispatch_get_global_queue(0,0), ^{
        BOOL ok = checkApproved(self->_serial);
        dispatch_async(dispatch_get_main_queue(), ^{
            if (ok) {
                [[NSUserDefaults standardUserDefaults] setBool:YES forKey:APPROVED_KEY];
                [[NSUserDefaults standardUserDefaults] synchronize];
                self->_statusLabel.text = @"✅ تم التحقق — مرحباً بك!";
                self->_statusLabel.textColor = [UIColor colorWithRed:0.2 green:0.9 blue:0.4 alpha:1];

                // تأثير اختفاء جميل
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5*NSEC_PER_SEC)),
                    dispatch_get_main_queue(), ^{
                    [UIView animateWithDuration:0.5
                        delay:0
                        options:UIViewAnimationOptionCurveEaseInOut
                        animations:^{
                            self.alpha = 0;
                            self.transform = CGAffineTransformMakeScale(1.05, 1.05);
                        } completion:^(BOOL f){
                            self->_authWin.hidden = YES;
                            [self removeFromSuperview];
                        }];
                });
            } else {
                self->_statusLabel.text = @"❌ غير مصرح — أرسل رمزك للمطور أولاً";
                self->_statusLabel.textColor = [UIColor colorWithRed:1 green:0.3 blue:0.3 alpha:1];
                self->_checkBtn.enabled = YES;
                self->_checkBtn.alpha = 1;

                // تأثير اهتزاز
                CAKeyframeAnimation *shake = [CAKeyframeAnimation animationWithKeyPath:@"transform.translation.x"];
                shake.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
                shake.duration = 0.4;
                shake.values = @[@(-8), @(8), @(-6), @(6), @(-4), @(4), @0];
                [self->_checkBtn.layer addAnimation:shake forKey:@"shake"];
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

        NSString *serial = generateCustomSerial();
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