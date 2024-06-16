//
//  UIWindow+Private.h
//  SurfVideo
//
//  Created by Jinwoo Kim on 6/1/24.
//

#import <UIKit/UIKit.h>
#import <TargetConditionals.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIWindow (Private)
#if TARGET_OS_VISION
- (NSUInteger)mrui_debugOptions API_DEPRECATED("", visionos(1.0, 2.0));
- (void)setMrui_debugOptions:(NSUInteger)debugOptions API_DEPRECATED("", visionos(1.0, 2.0));
#endif
@end

NS_ASSUME_NONNULL_END
