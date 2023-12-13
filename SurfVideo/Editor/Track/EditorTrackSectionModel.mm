//
//  EditorTrackSectionModel.mm
//  SurfVideo
//
//  Created by Jinwoo Kim on 12/14/23.
//

#import "EditorTrackSectionModel.hpp"

__attribute__((objc_direct_members))
@interface EditorTrackSectionModel ()
@property (assign, nonatomic) EditorTrackSectionModelType type;
@end

@implementation EditorTrackSectionModel

- (instancetype)initWithType:(EditorTrackSectionModelType)type {
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
        return _type == static_cast<EditorTrackSectionModel *>(other)->_type;
    }
}

- (NSUInteger)hash {
    return _type;
}

@end
