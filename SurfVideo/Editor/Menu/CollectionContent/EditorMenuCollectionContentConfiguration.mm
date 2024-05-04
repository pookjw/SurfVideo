//
//  EditorMenuCollectionContentConfiguration.mm
//  SurfVideo
//
//  Created by Jinwoo Kim on 2/27/24.
//

#import "EditorMenuCollectionContentConfiguration.hpp"
#import "EditorMenuCollectionContentView.hpp"

#if TARGET_OS_VISION

@implementation EditorMenuCollectionContentConfiguration

- (instancetype)initWithType:(EditorMenuItemModelType)type {
    if (self = [super init]) {
        _type = type;
    }
    
    return self;
}

- (BOOL)isEqual:(id)other {
    if (other == self) {
        return YES;
    } else if ([super isEqual:other]) {
        return YES;
    } else {
        return _type == static_cast<EditorMenuCollectionContentConfiguration *>(other)->_type;
    }
}

- (NSUInteger)hash {
    return _type;
}

- (id)copyWithZone:(struct _NSZone *)zone {
    decltype(self) copy = [self.class new];
    
    if (copy) {
        copy->_type = _type;
        copy->_delegate = _delegate;
    }
    
    return copy;
}

- (__kindof UIView<UIContentView> *)makeContentView {
    return [[[EditorMenuCollectionContentView alloc] initWithContentConfiguration:self] autorelease];
}

- (instancetype)updatedConfigurationForState:(id<UIConfigurationState>)state {
    return self;
}

@end

#endif
