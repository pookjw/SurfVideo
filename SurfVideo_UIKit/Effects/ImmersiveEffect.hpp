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
extern const ImmersiveEffect *allImmersiveEffects(NSUInteger * _Nullable outCount);

extern NSString * _Nullable NSStringFromImmersiveEffect(ImmersiveEffect immersiveEffect);
extern ImmersiveEffect ImmersiveEffectFromString(NSString *effectName, BOOL * _Nullable valid);

// ImmersiveEffectNumberKey, ImmersiveEffectReqestIDKey, ImmersiveEffectDurationTimeValueKey
extern NSNotificationName ImmersiveEffectAddEffectNotification;

// ImmersiveEffectReqestIDKey
extern NSNotificationName ImmersiveEffectRemoveEffectNotification;

extern NSString *ImmersiveEffectNumberKey;
extern NSString *ImmersiveEffectReqestIDKey;
extern NSString *ImmersiveEffectDurationTimeValueKey;

NS_ASSUME_NONNULL_END

#endif
