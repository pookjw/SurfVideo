//
//  EditorRenderCaption.mm
//  SurfVideo
//
//  Created by Jinwoo Kim on 2/21/24.
//

#import "EditorRenderCaption.hpp"
#import <AVFoundation/AVFoundation.h>

@implementation EditorRenderCaption

- (instancetype)initWithAttributedString:(NSAttributedString *)attributedString startTime:(CMTime)startTime endTime:(CMTime)endTime captionID:(NSUUID *)captionID {
    if (self = [super init]) {
        _attributedString = [attributedString copy];
        _startTime = startTime;
        _endTime = endTime;
        _captionID = [captionID copy];
    }
    
    return self;
}

- (void)dealloc {
    [_attributedString release];
    [_captionID release];
    [super dealloc];
}

- (id)copyWithZone:(struct _NSZone *)zone {
    EditorRenderCaption *copy = [super copyWithZone:zone];
    
    if (copy) {
        copy->_attributedString = [_attributedString copy];
        copy->_startTime = _startTime;
        copy->_endTime = _endTime;
        copy->_captionID = [_captionID copy];
    }
    
    return copy;
}

- (BOOL)isEqual:(id)other {
    if (other == self) {
        return YES;
    } else if (![super isEqual:other]) {
        return NO;
    } else {
        EditorRenderCaption *object = other;
        
        return [_attributedString isEqualToAttributedString:object->_attributedString] &&
        CMTimeCompare(_startTime, object->_startTime) == 0 &&
        CMTimeCompare(_endTime, object->_endTime) == 0 &&
        [_captionID isEqual:object->_captionID];
    }
}

- (NSUInteger)hash {
    return _attributedString.hash ^
    [NSValue valueWithCMTime:_startTime].hash ^
    [NSValue valueWithCMTime:_endTime].hash ^
    _captionID.hash;
}

@end
