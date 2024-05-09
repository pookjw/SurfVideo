//
//  SettingsItemModel.mm
//  SurfVideo
//
//  Created by Jinwoo Kim on 3/11/24.
//

#import "SettingsItemModel.hpp"

@implementation SettingsItemModel

- (instancetype)initWithType:(SettingsItemModelType)type {
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
