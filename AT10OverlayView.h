#import <UIKit/UIKit.h>

@interface AT10OverlayView : UIView

@property (nonatomic, copy) void (^onTap)(CGPoint pos);
@property (nonatomic, copy) NSString *credit;

+ (instancetype)sharedOverlay;
- (void)showInView:(UIView *)parentView;
- (void)hide;
- (BOOL)isRunning;

@end