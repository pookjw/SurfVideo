//
//  EditorTrackCollectionViewLayoutAttributes.mm
//  SurfVideo_AppKit
//
//  Created by Jinwoo Kim on 5/16/24.
//

#import "EditorTrackCollectionViewLayoutAttributes.hpp"

@implementation EditorTrackCollectionViewLayoutAttributes

- (void)dealloc {
    [_assetResolver release];
    [_timeResolver release];
    [super dealloc];
}

- (id)copyWithZone:(struct _NSZone *)zone {
    __kindof EditorTrackCollectionViewLayoutAttributes *copy = [super copyWithZone:zone];
    
    copy->_assetResolver = [_assetResolver copy];
    copy->_timeResolver = [_timeResolver copy];
    
    return copy;
}

@end
