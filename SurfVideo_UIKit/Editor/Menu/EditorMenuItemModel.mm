//
//  EditorMenuItemModel.mm
//  SurfVideo
//
//  Created by Jinwoo Kim on 2/23/24.
//

#import "EditorMenuItemModel.hpp"

#if TARGET_OS_VISION

@implementation EditorMenuItemModel

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
        return _type == static_cast<decltype(self)>(other)->_type;
    }
}

- (NSUInteger)hash {
    return _type;
}

@end

#endif
