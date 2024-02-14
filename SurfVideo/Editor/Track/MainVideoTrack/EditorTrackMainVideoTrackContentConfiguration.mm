//
//  EditorTrackMainVideoTrackContentConfiguration.mm
//  SurfVideo
//
//  Created by Jinwoo Kim on 12/17/23.
//

#import "EditorTrackMainVideoTrackContentConfiguration.hpp"
#import "EditorTrackMainVideoTrackContentView.hpp"

@implementation EditorTrackMainVideoTrackContentConfiguration

- (instancetype)initWithSectionModel:(EditorTrackSectionModel *)sectionModel itemModel:(EditorTrackItemModel *)itemModel {
    if (self = [super init]) {
        _sectionModel = [sectionModel retain];
        _itemModel = [itemModel retain];
    }
    
    return self;
}

- (void)dealloc {
    [_sectionModel release];
    [_itemModel release];
    [super dealloc];
}

- (BOOL)isEqual:(id)other {
    if (other == self) {
        return YES;
    } else if (![super isEqual:other]) {
        return NO;
    } else {
        if (![self.sectionModel isEqual:static_cast<decltype(self)>(other).sectionModel]) {
            return NO;
        }
        
        if (![self.itemModel isEqual:static_cast<decltype(self)>(other).itemModel]) {
            return NO;
        }
        
        return YES;
    }
}

- (NSUInteger)hash {
    return self.sectionModel.hash ^ self.itemModel.hash;
}

- (id)copyWithZone:(struct _NSZone *)zone {
    decltype(self) copy = [self.class new];
    
    if (copy) {
        copy->_sectionModel = [self.sectionModel retain];
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
