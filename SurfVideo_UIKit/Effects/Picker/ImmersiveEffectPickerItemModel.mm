//
//  ImmersiveEffectPickerItemModel.mm
//  SurfVideo_UIKit
//
//  Created by Jinwoo Kim on 6/1/24.
//

#import "ImmersiveEffectPickerItemModel.hpp"

@implementation ImmersiveEffectPickerItemModel

- (instancetype)initWithEffect:(ImmersiveEffect)effect {
    if (self = [super init]) {
        _effect = effect;
    }
    
    return self;
}

- (BOOL)isEqual:(id)other {
    if (other == self) {
        return YES;
    } else if ([super isEqual:other]) {
        return YES;
    } else {
        ImmersiveEffectPickerItemModel *object = other;
        
        return _effect == object->_effect;
    }
}

- (NSUInteger)hash {
    return _effect;
}

- (NSString *)title {
    switch (_effect) {
        case ImmersiveEffectFallingBalls:
            return @"Falling Balls";
        case ImmersiveEffectFireworks:
            return @"Fireworks";
        case ImmersiveEffectImpact:
            return @"Impact";
        case ImmersiveEffectMagic:
            return @"Magic";
        case ImmersiveEffectRain:
            return @"Rain";
        case ImmersiveEffectSnow:
            return @"Snow";
        case ImmersiveEffectSparks:
            return @"Sparks";
        default:
            return nil;
    }
}

@end
