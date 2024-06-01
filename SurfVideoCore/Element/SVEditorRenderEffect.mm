//
//  SVEditorRenderEffect.mm
//  SurfVideoCore
//
//  Created by Jinwoo Kim on 6/2/24.
//

#import <SurfVideoCore/SVEditorRenderEffect.hpp>
#import <AVFoundation/AVFoundation.h>

#if TARGET_OS_VISION

@implementation SVEditorRenderEffect

- (instancetype)initWithEffectName:(NSString *)effectName timeRange:(CMTimeRange)timeRange effectID:(NSUUID *)effectID {
    if (self = [super init]) {
        _effectName = [effectName copy];
        _timeRange = timeRange;
        _effectID = [effectID copy];
    }
    
    return self;
}

- (void)dealloc {
    [_effectName release];
    [_effectID release];
    [super dealloc];
}

- (id)copyWithZone:(struct _NSZone *)zone {
    SVEditorRenderEffect *copy = [super copyWithZone:zone];
    
    if (copy) {
        copy->_effectName = [_effectName copy];
        copy->_timeRange = _timeRange;
        copy->_effectID = [_effectID copy];
    }
    
    return copy;
}

- (BOOL)isEqual:(id)other {
    if (other == self) {
        return YES;
    } else if (![super isEqual:other]) {
        return NO;
    } else {
        SVEditorRenderEffect *object = other;
        
        return [_effectName isEqualToString:object->_effectName] &&
        CMTimeRangeEqual(_timeRange, object->_timeRange) &&
        [_effectID isEqual:object->_effectID];
    }
}

- (NSUInteger)hash {
    return _effectName.hash ^
    [NSValue valueWithCMTimeRange:_timeRange].hash ^
    _effectID.hash;
}

@end

#endif
