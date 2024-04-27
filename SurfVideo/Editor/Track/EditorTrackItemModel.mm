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

+ (EditorTrackItemModel *)videoTrackSegmentItemModelWithCompositionTrackSegment:(AVCompositionTrackSegment *)compositionTrackSegment compositionTrackSegmentName:(NSString *)compositionTrackSegmentName {
    return [[[EditorTrackItemModel alloc] initWithType:EditorTrackItemModelTypeVideoTrackSegment compositionTrackSegment:compositionTrackSegment compositionTrackSegmentName:compositionTrackSegmentName renderCaption:nil] autorelease];
}

+ (EditorTrackItemModel *)audioTrackSegmentItemModelWithCompositionTrackSegment:(AVCompositionTrackSegment *)compositionTrackSegment compositionTrackSegmentName:(NSString *)compositionTrackSegmentName {
    return [[[EditorTrackItemModel alloc] initWithType:EditorTrackItemModelTypeAudioTrackSegment compositionTrackSegment:compositionTrackSegment compositionTrackSegmentName:compositionTrackSegmentName renderCaption:nil] autorelease];
}

+ (EditorTrackItemModel *)captionItemModelWithRenderCaption:(EditorRenderCaption *)renderCaption {
    return [[[EditorTrackItemModel alloc] initWithType:EditorTrackItemModelTypeCaption compositionTrackSegment:nil compositionTrackSegmentName:nil renderCaption:renderCaption] autorelease];
}

- (instancetype)initWithType:(EditorTrackItemModelType)type compositionTrackSegment:(AVCompositionTrackSegment * _Nullable)compositionTrackSegment compositionTrackSegmentName:(NSString * _Nullable)compositionTrackSegmentName renderCaption:(EditorRenderCaption * _Nullable)renderCaption __attribute__((objc_direct)) {
    if (self = [super init]) {
        _type = type;
        _compositionTrackSegment = [compositionTrackSegment retain];
        _compositionTrackSegmentName = [compositionTrackSegmentName copy];
        _renderCaption = [renderCaption retain];
    }
    
    return self;
}

- (void)dealloc {
    [_compositionTrackSegment release];
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
        
        // TODO: EditorTrackSectionModel와 더불어, Composition ID 같은 것을 도입해서 type과 ID만 비교해야함. 아래처럼 TrackSegment를 비교하면 TrackSegment를 업데이트 후 reconfigure를 했을 때 발동이 안 될 것.
        return _type == object->_type &&
        [_compositionTrackSegment isEqual:object->_compositionTrackSegment] &&
        [_compositionTrackSegmentName isEqualToString:object->_compositionTrackSegmentName] &&
        [_renderCaption isEqual:object->_renderCaption];
    }
}

- (NSUInteger)hash {
    return _type ^ _compositionTrackSegment.hash ^ _compositionTrackSegmentName.hash ^ _renderCaption.hash;
}

@end
