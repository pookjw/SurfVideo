//
//  EditorRealityMenuContentConfiguration.mm
//  SurfVideo_UIKit
//
//  Created by Jinwoo Kim on 6/9/24.
//

#import "EditorRealityMenuContentConfiguration.hpp"

#if TARGET_OS_VISION

#import "EditorRealityMenuContnetView.hpp"

@implementation EditorRealityMenuContentConfiguration

- (instancetype)initWithItemModel:(EditorRealityMenuItemModel *)itemModel selected:(BOOL)selected {
    if (self = [super init]) {
        _itemModel = [itemModel retain];
        _selected = selected;
    }
    
    return self;
}

- (void)dealloc {
    [_itemModel release];
    [super dealloc];
}

- (id)copyWithZone:(struct _NSZone *)zone {
    decltype(self) copy = [self.class new];
    
    if (copy) {
        copy->_itemModel = [_itemModel retain];
        copy->_selected = _selected;
    }
    
    return copy;
}

- (__kindof UIView<UIContentView> *)makeContentView {
    return [[[EditorRealityMenuContnetView alloc] initWithContentConfiguration:self] autorelease];
}

- (instancetype)updatedConfigurationForState:(id<UIConfigurationState>)state {
    UICellConfigurationState *cellConfigurationState = (UICellConfigurationState *)state;
    _selected = cellConfigurationState.isSelected;
    
    return self; // TODO: selected
}

@end

#endif
