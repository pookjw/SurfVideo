//
//  _SVAssetThumbnailImageRequest.mm
//  SurfVideo
//
//  Created by Jinwoo Kim on 4/24/24.
//

#import "_SVAssetThumbnailImageRequest.hpp"
#import <UIKit/UIKit.h>

@implementation _SVAssetThumbnailImageRequest

- (instancetype)initWithAssetID:(NSUUID *)assetID assetImageGenerator:(AVAssetImageGenerator *)assetImageGenerator times:(NSOrderedSet<NSValue *> *)times maximumSize:(CGSize)maximumSize {
    if (self = [super init]) {
        _assetID = [assetID copy];
        _assetImageGenerator = [assetImageGenerator retain];
        _times = [times copy];
        _maximumSize = maximumSize;
        _completionBlocksByTime = [NSMutableDictionary new];
    }
    
    return self;
}

- (void)dealloc {
    [_assetID release];
    [_assetImageGenerator release];
    [_times release];
    [_completionBlocksByTime release];
    [super dealloc];
}

- (BOOL)isEqual:(id)other {
    if (other == self) {
        return YES;
    } else if (![super isEqual:other]) {
        return NO;
    } else {
        _SVAssetThumbnailImageRequest *object = other;
        
        return [_assetID isEqual:object->_assetID] &&
        [_assetImageGenerator isEqual:object->_assetImageGenerator] &&
        [_times isEqualToOrderedSet:object->_times] &&
        [_completionBlocksByTime isEqualToDictionary:object->_completionBlocksByTime] &&
        CGSizeEqualToSize(_maximumSize, object->_maximumSize);
    }
}

- (NSUInteger)hash {
    return _assetID.hash ^ 
    _times.hash ^
    [NSValue valueWithCGSize:_maximumSize].hash;
}

@end
