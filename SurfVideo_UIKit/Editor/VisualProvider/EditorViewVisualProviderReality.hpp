//
//  EditorViewVisualProviderReality.hpp
//  SurfVideo
//
//  Created by Jinwoo Kim on 5/4/24.
//

#import "EditorViewVisualProvider.hpp"
#import <TargetConditionals.h>

#if TARGET_OS_VISION

NS_ASSUME_NONNULL_BEGIN

__attribute__((objc_direct_members))
@interface EditorViewVisualProviderReality : EditorViewVisualProvider
@end

NS_ASSUME_NONNULL_END

#endif
