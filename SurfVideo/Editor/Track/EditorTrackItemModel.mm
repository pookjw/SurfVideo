//
//  EditorTrackItemModel.mm
//  SurfVideo
//
//  Created by Jinwoo Kim on 12/14/23.
//

#import "EditorTrackItemModel.hpp"

NSString * const EditorTrackItemModelCompositionTrackSegmentKey = @"trackSegment";
NSString * const EditorTrackItemModelTrackSegmentNameKey = @"trackSegmentName";
NSString * const EditorTrackItemModelRenderCaptionKey = @"renderCaption";

__attribute__((objc_direct_members))
@interface EditorTrackItemModel ()
@end

@implementation EditorTrackItemModel

- (instancetype)initWithType:(EditorTrackItemModelType)type {
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
    } else if ([super isEqual:other]) {
        return YES;
    } else {
        return _type == static_cast<decltype(self)>(other)->_type && [_userInfo isEqualToDictionary:static_cast<decltype(self)>(other)->_userInfo];
    }
}

- (NSUInteger)hash {
    return _type ^ _userInfo.hash;
}

@end
