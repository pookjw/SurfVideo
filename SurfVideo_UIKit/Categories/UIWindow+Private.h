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
- (NSUInteger)mrui_debugOptions;
- (void)setMrui_debugOptions:(NSUInteger)debugOptions;
#endif
@end

NS_ASSUME_NONNULL_END
