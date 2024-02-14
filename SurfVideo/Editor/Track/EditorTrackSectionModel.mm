//
//  EditorTrackSectionModel.mm
//  SurfVideo
//
//  Created by Jinwoo Kim on 12/14/23.
//

#import "EditorTrackSectionModel.hpp"

// AVCompositionTrack *
NSString * const EditorTrackSectionModelCompositionTrackKey = @"compositionTrack";

__attribute__((objc_direct_members))
@interface EditorTrackSectionModel ()
@end

@implementation EditorTrackSectionModel

- (instancetype)initWithType:(EditorTrackSectionModelType)type {
    if (self = [super init]) {
        _type = type;
    }
    
    return self;
}

- (void)dealloc {
    [_userInfo release];
    [super dealloc];
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

@end
