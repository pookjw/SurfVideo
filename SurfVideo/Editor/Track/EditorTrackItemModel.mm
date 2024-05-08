//
//  EditorTrackItemModel.mm
//  SurfVideo
//
//  Created by Jinwoo Kim on 12/14/23.
//

#import "EditorTrackItemModel.hpp"
__attribute__((objc_direct_members))
@interface EditorTrackItemModel ()
@end

@implementation EditorTrackItemModel

+ (EditorTrackItemModel *)videoTrackSegmentItemModelWithCompositionTrackSegment:(AVCompositionTrackSegment *)compositionTrackSegment composition:(AVComposition *)composition videoComposition:(AVVideoComposition *)videoComposition compositionID:(NSUUID *)compositionID compositionTrackSegmentName:(NSString *)compositionTrackSegmentName {
    return [[[EditorTrackItemModel alloc] initWithType:EditorTrackItemModelTypeVideoTrackSegment compositionTrackSegment:compositionTrackSegment composition:composition videoComposition:videoComposition compositionID:compositionID compositionTrackSegmentName:compositionTrackSegmentName renderCaption:nil] autorelease];
}

+ (EditorTrackItemModel *)audioTrackSegmentItemModelWithCompositionTrackSegment:(AVCompositionTrackSegment *)compositionTrackSegment composition:(AVComposition *)composition videoComposition:(AVVideoComposition *)videoComposition compositionID:(NSUUID *)compositionID compositionTrackSegmentName:(NSString *)compositionTrackSegmentName {
    return [[[EditorTrackItemModel alloc] initWithType:EditorTrackItemModelTypeAudioTrackSegment compositionTrackSegment:compositionTrackSegment composition:composition videoComposition:videoComposition compositionID:compositionID compositionTrackSegmentName:compositionTrackSegmentName renderCaption:nil] autorelease];
}

+ (EditorTrackItemModel *)captionItemModelWithRenderCaption:(EditorRenderCaption *)renderCaption composition:(AVComposition *)composition videoComposition:(AVVideoComposition *)videoComposition {
    return [[[EditorTrackItemModel alloc] initWithType:EditorTrackItemModelTypeCaption compositionTrackSegment:nil composition:composition videoComposition:videoComposition compositionID:nil compositionTrackSegmentName:nil renderCaption:renderCaption] autorelease];
}

- (instancetype)initWithType:(EditorTrackItemModelType)type compositionTrackSegment:(AVCompositionTrackSegment * _Nullable)compositionTrackSegment composition:(AVComposition *)composition videoComposition:(AVVideoComposition *)videoComposition compositionID:(NSUUID *)compositionID compositionTrackSegmentName:(NSString * _Nullable)compositionTrackSegmentName renderCaption:(EditorRenderCaption * _Nullable)renderCaption __attribute__((objc_direct)) {
    if (self = [super init]) {
        _type = type;
        _compositionTrackSegment = [compositionTrackSegment retain];
        _composition = [composition retain];
        _videoComposition = [videoComposition retain];
        _compositionID = [compositionID copy];
        _compositionTrackSegmentName = [compositionTrackSegmentName copy];
        _renderCaption = [renderCaption retain];
    }
    
    return self;
}

- (void)dealloc {
    [_compositionTrackSegment release];
    [_composition release];
    [_videoComposition release];
    [_compositionID release];
    [_compositionTrackSegmentName release];
    [_renderCaption release];
    [super dealloc];
}

- (BOOL)isEqual:(id)other {
    if (other == self) {
        return YES;
    } else if ([super isEqual:other]) {
        return YES;
    } else {
        EditorTrackItemModel *object = other;
        
        return _type == object->_type &&
        [_compositionID isEqual:object->_compositionID] &&
        [_renderCaption.captionID isEqual:object->_renderCaption.captionID];
    }
}

- (NSUInteger)hash {
    return _type ^ _compositionTrackSegment.hash ^ _compositionID.hash ^ _compositionTrackSegmentName.hash ^ _renderCaption.hash;
}

@end
