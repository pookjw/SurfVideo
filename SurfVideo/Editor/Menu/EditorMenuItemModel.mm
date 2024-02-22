//
//  EditorMenuItemModel.mm
//  SurfVideo
//
//  Created by Jinwoo Kim on 2/23/24.
//

#import "EditorMenuItemModel.hpp"

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
    } else if (![super isEqual:other]) {
        return NO;
    } else {
        return _type == static_cast<decltype(self)>(other)->_type;
    }
}

- (NSUInteger)hash {
    return _type;
}

- (UIImage *)image {
    switch (_type) {
        case EditorMenuItemModelTypeAddCaption:
            return [UIImage systemImageNamed:@"plus.bubble.fill"];
        case EditorMenuItemModelTypeEditCaption:
            return [UIImage systemImageNamed:@"textformat.size.larger"];
        case EditorMenuItemModelTypeChangeCaptionTime:
            return [UIImage systemImageNamed:@"timer"];
        default:
            return [UIImage systemImageNamed:@"questionmark.app.dashed"];
    }
}

@end
