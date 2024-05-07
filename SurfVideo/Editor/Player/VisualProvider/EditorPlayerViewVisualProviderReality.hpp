//
//  EditorPlayerViewVisualProviderReality.hpp
//  SurfVideo
//
//  Created by Jinwoo Kim on 5/7/24.
//

#import "EditorPlayerViewVisualProvider.hpp"
#import <TargetConditionals.h>

#if TARGET_OS_VISION

NS_ASSUME_NONNULL_BEGIN

__attribute__((objc_direct_members))
@interface EditorPlayerViewVisualProviderReality : EditorPlayerViewVisualProvider

@end

NS_ASSUME_NONNULL_END

#endif
