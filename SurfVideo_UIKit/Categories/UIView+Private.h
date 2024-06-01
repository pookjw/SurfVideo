//
//  UIView+Private.h
//  SurfVideo
//
//  Created by Jinwoo Kim on 2/21/24.
//

#import <UIKit/UIKit.h>
#import <TargetConditionals.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIView (Private)
#if TARGET_OS_VISION
- (void)sws_enablePlatter:(UIBlurEffectStyle)blurEffectStyle;
- (void)sws_updateCornerRadius;
- (void)sws_disablePlatter;
- (void)sws_disableDepthwiseClipping;
- (void)sws_enableDefaultUIShadow;
/*
 1, @"SwiftUI.Transform3D"
 
 - 1, 2
 - SwiftUI.AudioFeedback, _UIViewSeparatedStateRequestReasonUnspecified, SWSSeparatedStateRequestReasonPlatter, _UIViewSeparatedStateRequestReasonClipping, SwiftUI.Transform3D, 
 */
- (void)_requestSeparatedState:(NSInteger)state withReason:(NSString *)reason;
#endif
@end

NS_ASSUME_NONNULL_END
