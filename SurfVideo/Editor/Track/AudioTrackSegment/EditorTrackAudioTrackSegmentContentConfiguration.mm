//
//  EditorTrackAudioTrackSegmentContentConfiguration.mm
//  SurfVideo
//
//  Created by Jinwoo Kim on 3/10/24.
//

#import "EditorTrackAudioTrackSegmentContentConfiguration.hpp"
#import "EditorTrackAudioTrackSegmentContentView.hpp"

@implementation EditorTrackAudioTrackSegmentContentConfiguration

- (instancetype)initWithItemModel:(EditorTrackItemModel *)itemModel {
    if (self = [super init]) {
        _itemModel = [itemModel retain];
    }
    
    return self;
}

- (void)dealloc {
    [_itemModel release];
    [super dealloc];
}

- (__kindof UIView<UIContentView> *)makeContentView {
    EditorTrackAudioTrackSegmentContentView *contentView = [[EditorTrackAudioTrackSegmentContentView alloc] initWithContentConfiguration:self];
    return [contentView autorelease];
}

- (instancetype)updatedConfigurationForState:(id<UIConfigurationState>)state {
    return self;
}

- (BOOL)isEqual:(id)other {
    if (other == self) {
        return YES;
    } else if (![super isEqual:other]) {
        return NO;
    } else {
        if (![self.itemModel isEqual:static_cast<decltype(self)>(other).itemModel]) {
            return NO;
        }
        
        return YES;
    }
}

- (NSUInteger)hash {
    return self.itemModel.hash;
}

- (id)copyWithZone:(struct _NSZone *)zone {
    decltype(self) copy = [self.class new];
    
    if (copy) {
        copy->_itemModel = [self.itemModel retain];
    }
    
    return copy;
}

@end
