//
//  ImmersiveEffect.mm
//  SurfVideo_UIKit
//
//  Created by Jinwoo Kim on 6/1/24.
//

#import "ImmersiveEffect.hpp"

#if TARGET_OS_VISION

const ImmersiveEffect *allImmersiveEffects(NSUInteger *outCount) {
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

NSString *NSStringFromImmersiveEffect(ImmersiveEffect immersiveEffect) {
    switch (immersiveEffect) {
        case ImmersiveEffectFallingBalls:
            return @"ImmersiveEffectFallingBalls";
        case ImmersiveEffectFireworks:
            return @"ImmersiveEffectFireworks";
        case ImmersiveEffectImpact:
            return @"ImmersiveEffectImpact";
        case ImmersiveEffectMagic:
            return @"ImmersiveEffectMagic";
        case ImmersiveEffectRain:
            return @"ImmersiveEffectRain";
        case ImmersiveEffectSnow:
            return @"ImmersiveEffectSnow";
        case ImmersiveEffectSparks:
            return @"ImmersiveEffectSparks";
        default:
            return nil;
    }
}

ImmersiveEffect ImmersiveEffectFromString(NSString *effectName, BOOL *valid) {
    if ([effectName isEqualToString:@"ImmersiveEffectFallingBalls"]) {
        if (valid != NULL) {
            *valid = YES;
        }
        
        return ImmersiveEffectFallingBalls;
    } else if ([effectName isEqualToString:@"ImmersiveEffectFireworks"]) {
        if (valid != NULL) {
            *valid = YES;
        }
        
        return ImmersiveEffectFireworks;
    } else if ([effectName isEqualToString:@"ImmersiveEffectImpact"]) {
        if (valid != NULL) {
            *valid = YES;
        }
        
        return ImmersiveEffectImpact;
    } else if ([effectName isEqualToString:@"ImmersiveEffectMagic"]) {
        if (valid != NULL) {
            *valid = YES;
        }
        
        return ImmersiveEffectMagic;
    } else if ([effectName isEqualToString:@"ImmersiveEffectRain"]) {
        if (valid != NULL) {
            *valid = YES;
        }
        
        return ImmersiveEffectRain;
    } else if ([effectName isEqualToString:@"ImmersiveEffectSnow"]) {
        if (valid != NULL) {
            *valid = YES;
        }
        
        return ImmersiveEffectSnow;
    } else if ([effectName isEqualToString:@"ImmersiveEffectSparks"]) {
        if (valid != NULL) {
            *valid = YES;
        }
        
        return ImmersiveEffectSparks;
    } else {
        if (valid != NULL) {
            *valid = NO;
        }
        
        return ImmersiveEffectFallingBalls;
    }
}

NSNotificationName ImmersiveEffectAddEffectNotification = @"ImmersiveEffectAddEffectNotification";
NSNotificationName ImmersiveEffectRemoveEffectNotification = @"ImmersiveEffectRemoveEffectNotification";
NSString *ImmersiveEffectNumberKey = @"immersiveEffectNumber";
NSString *ImmersiveEffectReqestIDKey = @"requestID";
NSString *ImmersiveEffectDurationTimeValueKey = @"durationTimeValue";

#endif
