//
//  ImmersiveEffect.mm
//  SurfVideo_UIKit
//
//  Created by Jinwoo Kim on 6/1/24.
//

#import "ImmersiveEffect.hpp"

#if TARGET_OS_VISION

const ImmersiveEffect *allImmersiveEffectTypes(NSUInteger *outCount) {
    if (outCount != NULL) {
        *outCount = 7;
    }
    
    static const ImmersiveEffect _allImmersiveEffectTypes[7] = {
        ImmersiveEffectFallingBalls,
        ImmersiveEffectFireworks,
        ImmersiveEffectImpact,
        ImmersiveEffectMagic,
        ImmersiveEffectRain,
        ImmersiveEffectSnow,
        ImmersiveEffectSparks
    };
    
    return _allImmersiveEffectTypes;
}

NSNotificationName ImmersiveEffectDidSelectEffectNotification = @"ImmersiveEffectDidSelectEffectNotification";
NSString *ImmersiveEffectSelectedEffectKey = @"selectedEffect";

#endif
