//
//  EditorRealityMenuItemModel.mm
//  SurfVideo_UIKit
//
//  Created by Jinwoo Kim on 6/9/24.
//

#import "EditorRealityMenuItemModel.hpp"

@implementation EditorRealityMenuItemModel

- (instancetype)initWithType:(EditorRealityMenuItemModelType)type {
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
