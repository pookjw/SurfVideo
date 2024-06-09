//
//  UIScrollView+ScrollWithHandTracking.hpp
//  SurfVideo_UIKit
//
//  Created by Jinwoo Kim on 6/9/24.
//

#import <TargetConditionals.h>

#if TARGET_OS_VISION

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

__attribute__((objc_direct_members))
@interface UIScrollView (ScrollWithHandTracking)
- (void)sv_enableHandTrackingHorizontalScrollingWithSensitivity:(double)sensitivity;
- (void)sv_disableHandTrackingHorizontalScrolling;
@end

NS_ASSUME_NONNULL_END

#endif
