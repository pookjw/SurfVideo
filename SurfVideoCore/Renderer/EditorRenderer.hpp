//
//  EditorRenderer.hpp
//  SurfVideo
//
//  Created by Jinwoo Kim on 2/20/24.
//

#import <AVFoundation/AVFoundation.h>
#import <SurfVideoCore/EditorRenderElement.hpp>

NS_ASSUME_NONNULL_BEGIN

@interface EditorRenderer : NSObject
+ (void)videoCompositionWithComposition:(AVComposition *)composition elements:(NSArray<__kindof EditorRenderElement *> *)elements completionHandler:(void (^)(AVVideoComposition * _Nullable videoComposition, NSError * _Nullable error))completionHandler;
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
@end

NS_ASSUME_NONNULL_END
