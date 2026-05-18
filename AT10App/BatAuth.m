#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <CommonCrypto/CommonDigest.h>

#define BOT_TOKEN     @"8749324584:AAGp42yegRDpU9NLFu9B_WZWW2WzSn_0_Uc"
#define OWNER_CHAT_ID @"8139813376"
#define APPROVED_KEY  @"bat_v1_approved"
#define CODE_KEY      @"bat_v1_code"

// نولد كود فريد للجهاز — مشفر ومو تسلسلي
static NSString *getDeviceCode(void) {
    NSString *saved = [[NSUserDefaults standardUserDefaults] stringForKey:CODE_KEY];
    if (saved && saved.length > 0) return saved;

    NSString *raw = [NSString stringWithFormat:@"AST7ALH-%@-%ld",
        [UIDevice currentDevice].identifierForVendor.UUIDString,
        (long)([[NSDate date] timeIntervalSince1970])];

    const char *c = raw.UTF8String;
    unsigned char r[CC_MD5_DIGEST_LENGTH];
    CC_MD5(c, (CC_LONG)strlen(c), r);

    // شكل جميل XXXX-XXXX-XXXX
    NSString *code = [NSString stringWithFormat:@"%02X%02X-%02X%02X-%02X%02X",
        r[0],r[1],r[2],r[3],r[4],r[5]];

    [[NSUserDefaults standardUserDefaults] setObject:code forKey:CODE_KEY];
    [[NSUserDefaults standardUserDefaults] synchronize];
    return code;
}

static void sendToBot(NSString *code) {
    dispatch_async(dispatch_get_global_queue(0,0), ^{
        NSString *msg = [NSString stringWithFormat:
            @"🔑 طلب ترخيص جديد\n"
            @"━━━━━━━━━━━━━━\n"
            @"⌗ AsT7aLh\n\n"
            @"الكود:\n"
            @"`%@`\n\n"
            @"للموافقة أرسل الكود هنا", code];

        NSString *url = [NSString stringWithFormat:
            @"https://api.telegram.org/bot%@/sendMessage?chat_id=%@&text=%@&parse_mode=Markdown",
            BOT_TOKEN, OWNER_CHAT_ID,
            [msg stringByAddingPercentEncodingWithAllowedCharacters:
                [NSCharacterSet URLQueryAllowedCharacterSet]]];
        [NSData dataWithContentsOfURL:[NSURL URLWithString:url]];
    });
}

static BOOL checkApproved(NSString *code) {
    NSURLRequest *req = [NSURLRequest requestWithURL:
        [NSURL URLWithString:[NSString stringWithFormat:
            @"https://api.telegram.org/bot%@/getUpdates?limit=100&offset=-100", BOT_TOKEN]]
        cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
        timeoutInterval:10];

    NSData *d = [NSURLConnection sendSynchronousRequest:req returningResponse:nil error:nil];
    if (!d) return NO;
    NSDictionary *j = [NSJSONSerialization JSONObjectWithData:d options:0 error:nil];
    for (NSDictionary *update in j[@"result"]) {
        NSString *text = update[@"message"][@"text"];
        if (text && [text containsString:code]) return YES;
    }
    return NO;
}

// ===== الواجهة =====
@interface BatAuthView : UIView
@property (nonatomic, strong) NSString *code;
@property (nonatomic, strong) UILabel  *statusLbl;
@property (nonatomic, strong) UIButton *checkBtn;
@property (nonatomic, strong) UIButton *copyBtn2;
@property (nonatomic, weak)   UIWindow *win;
@end

@implementation BatAuthView

- (instancetype)initWithWindow:(UIWindow *)win {
    self = [super initWithFrame:UIScreen.mainScreen.bounds];
    if (!self) return nil;
    _win  = win;
    _code = getDeviceCode();
    self.userInteractionEnabled = YES;
    [self setupBackground];
    [self setupUI];
    sendToBot(_code);
    return self;
}

- (void)setupBackground {
    // خلفية متدرجة داكنة
    CAGradientLayer *bg = [CAGradientLayer layer];
    bg.frame = self.bounds;
    bg.colors = @[
        (id)[UIColor colorWithRed:0.02 green:0.02 blue:0.06 alpha:1].CGColor,
        (id)[UIColor colorWithRed:0.04 green:0.08 blue:0.16 alpha:1].CGColor,
        (id)[UIColor colorWithRed:0.02 green:0.02 blue:0.06 alpha:1].CGColor,
    ];
    bg.startPoint = CGPointMake(0,0);
    bg.endPoint   = CGPointMake(1,1);
    [self.layer addSublayer:bg];

    // جزيئات متحركة
    CAEmitterLayer *emitter = [CAEmitterLayer layer];
    emitter.frame = self.bounds;
    emitter.emitterPosition = CGPointMake(self.bounds.size.width/2, -10);
    emitter.emitterSize = CGSizeMake(self.bounds.size.width, 0);
    emitter.emitterShape = kCAEmitterLayerLine;

    CAEmitterCell *cell = [CAEmitterCell emitterCell];
    cell.birthRate = 2;
    cell.lifetime  = 12;
    cell.velocity  = 40;
    cell.velocityRange = 20;
    cell.emissionLongitude = M_PI;
    cell.scale = 0.15;
    cell.scaleRange = 0.1;
    cell.alphaSpeed = -0.07;
    cell.color = [UIColor colorWithRed:0.3 green:0.6 blue:1 alpha:0.6].CGColor;

    UIGraphicsBeginImageContextWithOptions(CGSizeMake(6,6), NO, 0);
    [[UIColor whiteColor] setFill];
    [[UIBezierPath bezierPathWithOvalInRect:CGRectMake(0,0,6,6)] fill];
    cell.contents = (id)UIGraphicsGetImageFromCurrentImageContext().CGImage;
    UIGraphicsEndImageContext();

    emitter.emitterCells = @[cell];
    [self.layer addSublayer:emitter];
}

- (void)setupUI {
    CGFloat W = self.bounds.size.width;
    CGFloat H = self.bounds.size.height;

    // دائرة الشعار
    UIView *circle = [[UIView alloc] initWithFrame:CGRectMake(W/2-55, H*0.1, 110, 110)];
    circle.layer.cornerRadius = 55;
    circle.backgroundColor = [UIColor colorWithRed:0.094 green:0.373 blue:0.647 alpha:0.15];
    circle.layer.borderWidth = 1.5;
    circle.layer.borderColor = [UIColor colorWithRed:0.216 green:0.541 blue:0.867 alpha:0.4].CGColor;
    circle.layer.shadowColor = [UIColor colorWithRed:0.094 green:0.373 blue:0.867 alpha:1].CGColor;
    circle.layer.shadowOpacity = 0.6;
    circle.layer.shadowRadius = 20;
    circle.layer.shadowOffset = CGSizeZero;
    [self addSubview:circle];

    // تأثير نبض على الدائرة
    CABasicAnimation *pulse = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
    pulse.fromValue = @(1.0);
    pulse.toValue   = @(1.08);
    pulse.duration  = 2.0;
    pulse.autoreverses = YES;
    pulse.repeatCount  = HUGE_VALF;
    pulse.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    [circle.layer addAnimation:pulse forKey:@"pulse"];

    UILabel *icon = [[UILabel alloc] initWithFrame:circle.bounds];
    icon.text = @"⌗";
    icon.font = [UIFont boldSystemFontOfSize:44];
    icon.textAlignment = NSTextAlignmentCenter;
    icon.textColor = [UIColor colorWithRed:0.216 green:0.541 blue:0.867 alpha:1];
    [circle addSubview:icon];

    // اسم صاحب الأداة
    UILabel *name = [[UILabel alloc] initWithFrame:CGRectMake(0, H*0.28, W, 36)];
    name.text = @"AsT7aLh";
    name.font = [UIFont boldSystemFontOfSize:28];
    name.textColor = UIColor.whiteColor;
    name.textAlignment = NSTextAlignmentCenter;
    name.alpha = 0;
    [self addSubview:name];
    [UIView animateWithDuration:1.0 delay:0.4 options:0 animations:^{
        name.alpha = 1;
    } completion:nil];

    // خط فاصل
    UIView *line = [[UIView alloc] initWithFrame:CGRectMake(W*0.25, H*0.35, W*0.5, 0.5)];
    line.backgroundColor = [UIColor colorWithRed:0.216 green:0.541 blue:0.867 alpha:0.25];
    [self addSubview:line];

    // وصف
    UILabel *desc = [[UILabel alloc] initWithFrame:CGRectMake(20, H*0.37, W-40, 44)];
    desc.text = @"أداة محمية — أرسل الكود للمطور\nللحصول على صلاحية الدخول";
    desc.font = [UIFont systemFontOfSize:13];
    desc.textColor = [UIColor colorWithWhite:1 alpha:0.45];
    desc.textAlignment = NSTextAlignmentCenter;
    desc.numberOfLines = 2;
    [self addSubview:desc];

    // صندوق الكود
    UIView *box = [[UIView alloc] initWithFrame:CGRectMake(20, H*0.46, W-40, 58)];
    box.backgroundColor = [UIColor colorWithRed:0.094 green:0.373 blue:0.647 alpha:0.1];
    box.layer.cornerRadius = 14;
    box.layer.borderWidth = 1;
    box.layer.borderColor = [UIColor colorWithRed:0.216 green:0.541 blue:0.867 alpha:0.3].CGColor;
    box.layer.shadowColor = [UIColor colorWithRed:0.094 green:0.373 blue:0.867 alpha:1].CGColor;
    box.layer.shadowOpacity = 0.2;
    box.layer.shadowRadius = 12;
    box.layer.shadowOffset = CGSizeZero;
    [self addSubview:box];

    UILabel *codeLbl = [[UILabel alloc] initWithFrame:CGRectMake(12,0,W-112,58)];
    codeLbl.text = _code;
    codeLbl.font = [UIFont monospacedSystemFontOfSize:18 weight:UIFontWeightBold];
    codeLbl.textColor = [UIColor colorWithRed:0.4 green:0.75 blue:1 alpha:1];
    codeLbl.textAlignment = NSTextAlignmentCenter;
    codeLbl.adjustsFontSizeToFitWidth = YES;
    [box addSubview:codeLbl];

    _copyBtn2 = [UIButton buttonWithType:UIButtonTypeCustom];
    _copyBtn2.frame = CGRectMake(W-100, 14, 72, 30);
    _copyBtn2.backgroundColor = [UIColor colorWithRed:0.094 green:0.373 blue:0.647 alpha:0.8];
    _copyBtn2.layer.cornerRadius = 8;
    [_copyBtn2 setTitle:@"نسخ" forState:UIControlStateNormal];
    _copyBtn2.titleLabel.font = [UIFont boldSystemFontOfSize:13];
    [_copyBtn2 addTarget:self action:@selector(doCopy) forControlEvents:UIControlEventTouchUpInside];
    [box addSubview:_copyBtn2];

    // زر تحقق
    _checkBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    _checkBtn.frame = CGRectMake(20, H*0.59, W-40, 52);
    _checkBtn.layer.cornerRadius = 14;
    _checkBtn.titleLabel.font = [UIFont boldSystemFontOfSize:16];
    [_checkBtn setTitle:@"تحقق من الصلاحية" forState:UIControlStateNormal];
    [_checkBtn setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];

    CAGradientLayer *btnG = [CAGradientLayer layer];
    btnG.frame = CGRectMake(0,0,W-40,52);
    btnG.cornerRadius = 14;
    btnG.colors = @[
        (id)[UIColor colorWithRed:0.094 green:0.373 blue:0.647 alpha:1].CGColor,
        (id)[UIColor colorWithRed:0.15 green:0.5 blue:0.9 alpha:1].CGColor
    ];
    btnG.startPoint = CGPointMake(0,0.5);
    btnG.endPoint   = CGPointMake(1,0.5);
    [_checkBtn.layer insertSublayer:btnG atIndex:0];
    _checkBtn.layer.shadowColor = [UIColor colorWithRed:0.094 green:0.373 blue:0.867 alpha:1].CGColor;
    _checkBtn.layer.shadowOpacity = 0.5;
    _checkBtn.layer.shadowRadius  = 12;
    _checkBtn.layer.shadowOffset  = CGSizeMake(0,4);
    [_checkBtn addTarget:self action:@selector(doCheck) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:_checkBtn];

    // حالة
    _statusLbl = [[UILabel alloc] initWithFrame:CGRectMake(20,H*0.7,W-40,36)];
    _statusLbl.text = @"أرسل الكود للمطور ثم اضغط تحقق";
    _statusLbl.font = [UIFont systemFontOfSize:12];
    _statusLbl.textColor = [UIColor colorWithWhite:1 alpha:0.4];
    _statusLbl.textAlignment = NSTextAlignmentCenter;
    _statusLbl.numberOfLines = 2;
    [self addSubview:_statusLbl];

    // حقوق
    UILabel *cr = [[UILabel alloc] initWithFrame:CGRectMake(0,H-34,W,24)];
    cr.text = @"⌗ 10th battalión | AsT7aLh | استحالة";
    cr.font = [UIFont systemFontOfSize:10];
    cr.textColor = [UIColor colorWithWhite:1 alpha:0.18];
    cr.textAlignment = NSTextAlignmentCenter;
    [self addSubview:cr];
}

- (void)doCopy {
    [UIPasteboard generalPasteboard].string = _code;
    [_copyBtn2 setTitle:@"✓" forState:UIControlStateNormal];
    _copyBtn2.backgroundColor = [UIColor colorWithRed:0.1 green:0.65 blue:0.3 alpha:0.9];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2*NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [self->_copyBtn2 setTitle:@"نسخ" forState:UIControlStateNormal];
        self->_copyBtn2.backgroundColor = [UIColor colorWithRed:0.094 green:0.373 blue:0.647 alpha:0.8];
    });
}

- (void)doCheck {
    _statusLbl.text = @"⏳ جاري التحقق...";
    _statusLbl.textColor = [UIColor colorWithWhite:1 alpha:0.6];
    _checkBtn.enabled = NO;
    _checkBtn.alpha   = 0.65;

    dispatch_async(dispatch_get_global_queue(0,0), ^{
        BOOL ok = checkApproved(self->_code);
        dispatch_async(dispatch_get_main_queue(), ^{
            if (ok) {
                [[NSUserDefaults standardUserDefaults] setBool:YES forKey:APPROVED_KEY];
                [[NSUserDefaults standardUserDefaults] synchronize];
                self->_statusLbl.text = @"✅ تم التحقق — مرحباً بك!";
                self->_statusLbl.textColor = [UIColor colorWithRed:0.2 green:0.9 blue:0.5 alpha:1];
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5*NSEC_PER_SEC)),
                    dispatch_get_main_queue(), ^{
                    [UIView animateWithDuration:0.6 delay:0
                        options:UIViewAnimationOptionCurveEaseIn
                        animations:^{
                            self.alpha = 0;
                            self.transform = CGAffineTransformMakeScale(0.95, 0.95);
                        } completion:^(BOOL f){
                            self->_win.hidden = YES;
                            [self removeFromSuperview];
                        }];
                });
            } else {
                self->_statusLbl.text = @"❌ غير مصرح — أرسل الكود للمطور أولاً";
                self->_statusLbl.textColor = [UIColor colorWithRed:1 green:0.35 blue:0.35 alpha:1];
                self->_checkBtn.enabled = YES;
                self->_checkBtn.alpha   = 1;
                CAKeyframeAnimation *shake = [CAKeyframeAnimation animationWithKeyPath:@"transform.translation.x"];
                shake.values = @[@(-10),@(10),@(-8),@(8),@(-5),@(5),@0];
                shake.duration = 0.45;
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

        NSString *code     = getDeviceCode();
        BOOL      approved = [[NSUserDefaults standardUserDefaults] boolForKey:APPROVED_KEY];

        if (approved) {
            // تحقق خفي في الخلفية
            dispatch_async(dispatch_get_global_queue(0,0), ^{
                BOOL still = checkApproved(code);
                if (!still) {
                    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:APPROVED_KEY];
                    [[NSUserDefaults standardUserDefaults] synchronize];
                    dispatch_async(dispatch_get_main_queue(), ^{ abort(); });
                }
            });
            return; // دخل مرة قبل — ما يطلع عليه شيء
        }

        UIWindowScene *scene = nil;
        for (UIScene *s in UIApplication.sharedApplication.connectedScenes)
            if ([s isKindOfClass:[UIWindowScene class]]) { scene = (UIWindowScene *)s; break; }

        BatAuthWin *win = scene ?
            [[BatAuthWin alloc] initWithWindowScene:scene] :
            [[BatAuthWin alloc] initWithFrame:UIScreen.mainScreen.bounds];

        win.windowLevel      = UIWindowLevelAlert + 999;
        win.userInteractionEnabled = YES;
        win.backgroundColor  = UIColor.blackColor;

        UIViewController *vc = [[UIViewController alloc] init];
        vc.view.backgroundColor = UIColor.clearColor;
        win.rootViewController  = vc;
        win.hidden = NO;

        BatAuthView *auth = [[BatAuthView alloc] initWithWindow:win];
        [vc.view addSubview:auth];

        static BatAuthWin *retained;
        retained = win;
    });
}