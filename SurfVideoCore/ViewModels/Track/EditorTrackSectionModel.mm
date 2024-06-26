//
//  EditorTrackSectionModel.mm
//  SurfVideo
//
//  Created by Jinwoo Kim on 12/14/23.
//

#import <SurfVideoCore/EditorTrackSectionModel.hpp>

__attribute__((objc_direct_members))
@interface EditorTrackSectionModel ()
@end

@implementation EditorTrackSectionModel

+ (EditorTrackSectionModel *)mainVideoTrackSectionModelWithComposition:(AVComposition *)composotion compositionTrack:(AVCompositionTrack *)compositionTrack {
    return [[[EditorTrackSectionModel alloc] initWithType:EditorTrackSectionModelTypeMainVideoTrack composition:composotion compositionTrack:compositionTrack] autorelease];
}

+ (EditorTrackSectionModel *)audioTrackSectionModelWithComposition:(AVComposition *)composotion compositionTrack:(AVCompositionTrack *)compositionTrack {
    return [[[EditorTrackSectionModel alloc] initWithType:EditorTrackSectionModelTypeAudioTrack composition:composotion compositionTrack:compositionTrack] autorelease];
}

+ (EditorTrackSectionModel *)captionTrackSectionModelWithComposition:(AVComposition *)composotion {
    return [[[EditorTrackSectionModel alloc] initWithType:EditorTrackSectionModelTypeCaptionTrack composition:composotion compositionTrack:nil] autorelease];
}

+ (EditorTrackSectionModel *)effectTrackSectionModelWithComposition:(AVComposition *)composotion {
    return [[[EditorTrackSectionModel alloc] initWithType:EditorTrackSectionModelTypeEffectTrack composition:composotion compositionTrack:nil] autorelease];
}

- (instancetype)initWithType:(EditorTrackSectionModelType)type composition:(AVComposition *)composition compositionTrack:(AVCompositionTrack * _Nullable)compositionTrack __attribute__((objc_direct)) {
    if (self = [super init]) {
        _type = type;
        _composition = [composition retain];
        _compositionTrack = [compositionTrack retain];
    }
    
    return self;
}

- (void)dealloc {
    [_composition release];
    [_compositionTrack release];
    [super dealloc];
}

- (BOOL)isEqual:(id)other {
    if (other == self) {
        return YES;
    } else if ([super isEqual:other]) {
        return YES;
    } else {
        EditorTrackSectionModel *object = other;
        
        return _type == object->_type;
    }
}

- (NSUInteger)hash {
    return _type;
}

@end
