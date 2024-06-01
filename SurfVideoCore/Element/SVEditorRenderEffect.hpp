//
//  SVEditorRenderEffect.hpp
//  SurfVideoCore
//
//  Created by Jinwoo Kim on 6/2/24.
//

#import <TargetConditionals.h>

#if TARGET_OS_VISION

#import <SurfVideoCore/SVEditorRenderElement.hpp>
#import <CoreMedia/CoreMedia.h>

NS_ASSUME_NONNULL_BEGIN

@interface SVEditorRenderEffect : SVEditorRenderElement
@property (copy, readonly, nonatomic) NSString *effectName;
@property (assign, readonly, nonatomic) CMTimeRange timeRange;
@property (copy, readonly, nonatomic) NSUUID *effectID;
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithEffectName:(NSString *)effectName timeRange:(CMTimeRange)timeRange effectID:(NSUUID *)effectID NS_DESIGNATED_INITIALIZER;
@end

NS_ASSUME_NONNULL_END

#endif
