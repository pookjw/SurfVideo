//
//  EditorAssetPreviewLayerDelegate.hpp
//  SurfVideo
//
//  Created by Jinwoo Kim on 2/13/24.
//

#import <QuartzCore/QuartzCore.h>

NS_ASSUME_NONNULL_BEGIN

__attribute__((objc_direct_members))
@interface EditorAssetPreviewLayerDelegate : NSObject <CALayerDelegate>
@property (class, readonly, nonatomic) void *imageContextKey;
@end

NS_ASSUME_NONNULL_END
