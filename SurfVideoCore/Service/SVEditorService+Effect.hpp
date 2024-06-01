//
//  SVEditorService+Effect.hpp
//  SurfVideoCore
//
//  Created by Jinwoo Kim on 6/2/24.
//

#import <SurfVideoCore/SVEditorService.hpp>
#import <SurfVideoCore/SVEditorRenderEffect.hpp>
#import <CoreMedia/CoreMedia.h>

NS_ASSUME_NONNULL_BEGIN

@interface SVEditorService (Effect)
- (void)appendEffectWithName:(NSString *)effectName timeRange:(CMTimeRange)timeRange completionHandler:(EditorServiceCompletionHandler)completionHandler;
- (void)removeEffect:(SVEditorRenderEffect *)effect completionHandler:(EditorServiceCompletionHandler)completionHandler;
- (void)renderEffectsAtTime:(CMTime)time completionHandler:(void (^)(NSArray<SVEditorRenderEffect *> *effects))completionHandler;
@end

NS_ASSUME_NONNULL_END
