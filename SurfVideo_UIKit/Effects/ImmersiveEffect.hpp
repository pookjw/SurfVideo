//
//  ImmersiveEffect.hpp
//  SurfVideo_UIKit
//
//  Created by Jinwoo Kim on 6/1/24.
//
#import <TargetConditionals.h>

#if TARGET_OS_VISION

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, ImmersiveEffect) {
    ImmersiveEffectFallingBalls,
    ImmersiveEffectFireworks,
    ImmersiveEffectImpact,
    ImmersiveEffectMagic,
    ImmersiveEffectRain,
    ImmersiveEffectSnow,
    ImmersiveEffectSparks
};

// do not call free()
extern const ImmersiveEffect *allImmersiveEffectTypes(NSUInteger * _Nullable outCount);

extern NSNotificationName ImmersiveEffectDidSelectEffectNotification;
extern NSString *ImmersiveEffectSelectedEffectKey;

NS_ASSUME_NONNULL_END

#endif
