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
- (void)_requestSeparatedState:(NSInteger)state withReason:(NSString *)reason; // Recommended: 1, @"SwiftUI.Transform3D"
#endif
@end

NS_ASSUME_NONNULL_END
