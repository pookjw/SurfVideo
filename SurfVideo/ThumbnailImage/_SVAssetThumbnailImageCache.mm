//
//  _SVAssetThumbnailImageCache.mm
//  SurfVideo
//
//  Created by Jinwoo Kim on 4/24/24.
//

#import "_SVAssetThumbnailImageCache.hpp"
#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>

@implementation _SVAssetThumbnailImageCache

- (instancetype)initWithAssetID:(NSUUID *)assetID requestedTime:(CMTime)requestedTime actualTime:(CMTime)actualTime image:(CGImageRef)image maximumSize:(CGSize)maximumSize {
    if (self = [super init]) {
        _assetID = [assetID copy];
        _requestedTime = requestedTime;
        _actualTime = actualTime;
        _image = image;
        _maximumSize = maximumSize;
        CGImageRetain(image);
    }
    
    return self;
}

- (void)dealloc {
    [_assetID release];
    
    if (auto image = _image) {
        CGImageRelease(image);
    }
    
    [super dealloc];
}

- (BOOL)isEqual:(id)other {
    if (other == self) {
        return YES;
    } else if (![super isEqual:other]) {
        return NO;
    } else {
        _SVAssetThumbnailImageCache *object = other;
        return [_assetID isEqual:object->_assetID] &&
        (CMTimeCompare(_requestedTime, object->_requestedTime) == 0) &&
        (CMTimeCompare(_actualTime, object->_actualTime) == 0) &&
        CGSizeEqualToSize(_maximumSize, object->_maximumSize);
    }
}

- (NSUInteger)hash {
    return _assetID.hash ^
    [NSValue valueWithCMTime:_requestedTime].hash ^
    [NSValue valueWithCMTime:_actualTime].hash ^
    [NSValue valueWithCGSize:_maximumSize].hash;
}

@end
