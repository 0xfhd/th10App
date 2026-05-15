#ifndef AT10OverlayView_h
#define AT10OverlayView_h
#import <UIKit/UIKit.h>
NS_ASSUME_NONNULL_BEGIN

@interface AT10OverlayView : UIView
@property (nonatomic, readonly) BOOL      isRunning;
@property (nonatomic, readonly) CGPoint   dotPosition;
@property (nonatomic, readonly) long      totalClicks;
@property (nonatomic, readonly) NSString *credit;
@property (nonatomic, copy, nullable) void (^onTap)(CGPoint position);

+ (instancetype)sharedOverlay;
- (void)showInView:(UIView *)parentView;
- (void)hide;
@end

NS_ASSUME_NONNULL_END
#endif
