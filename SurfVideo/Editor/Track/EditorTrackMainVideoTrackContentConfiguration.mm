//
//  EditorTrackMainVideoTrackContentConfiguration.mm
//  SurfVideo
//
//  Created by Jinwoo Kim on 12/17/23.
//

#import "EditorTrackMainVideoTrackContentConfiguration.hpp"
#import "EditorTrackMainVideoTrackContentView.hpp"

@implementation EditorTrackMainVideoTrackContentConfiguration

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

- (BOOL)isEqual:(id)other {
    if (other == self) {
        return YES;
    } else if (![super isEqual:other]) {
        return NO;
    } else {
        return [self.itemModel isEqual:static_cast<decltype(self)>(other).itemModel];
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

- (nonnull __kindof UIView<UIContentView> *)makeContentView {
    EditorTrackMainVideoTrackContentView *contentView = [[EditorTrackMainVideoTrackContentView alloc] initWithContentConfiguration:self];
    return [contentView autorelease];
}

- (nonnull instancetype)updatedConfigurationForState:(nonnull id<UIConfigurationState>)state {
    return self;
}

@end
