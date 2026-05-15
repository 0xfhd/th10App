#import "AT10OverlayWindow.h"

@implementation AT10OverlayWindow

// أهم شيء: النافذة لا تستقبل لمس أبداً
- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    return NO; // تمرير اللمس للعبة دائماً
}

@end
