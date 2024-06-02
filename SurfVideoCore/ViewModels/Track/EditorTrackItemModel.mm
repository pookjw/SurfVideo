//
//  EditorTrackItemModel.mm
//  SurfVideo
//
//  Created by Jinwoo Kim on 12/14/23.
//

#import <SurfVideoCore/EditorTrackItemModel.hpp>

__attribute__((objc_direct_members))
@interface EditorTrackItemModel ()
@end

@implementation EditorTrackItemModel

+ (EditorTrackItemModel *)videoTrackSegmentItemModelWithCompositionTrackSegment:(AVCompositionTrackSegment *)compositionTrackSegment composition:(AVComposition *)composition compositionID:(NSUUID *)compositionID compositionTrackSegmentName:(NSString *)compositionTrackSegmentName {
    return [[[EditorTrackItemModel alloc] initWithType:EditorTrackItemModelTypeVideoTrackSegment
                               compositionTrackSegment:compositionTrackSegment
                                           composition:composition
                                         compositionID:compositionID
                           compositionTrackSegmentName:compositionTrackSegmentName
                                         renderCaption:nil
                                          renderEffect:nil] autorelease];
}

+ (EditorTrackItemModel *)audioTrackSegmentItemModelWithCompositionTrackSegment:(AVCompositionTrackSegment *)compositionTrackSegment composition:(AVComposition *)composition compositionID:(NSUUID *)compositionID compositionTrackSegmentName:(NSString *)compositionTrackSegmentName {
    return [[[EditorTrackItemModel alloc] initWithType:EditorTrackItemModelTypeAudioTrackSegment
                               compositionTrackSegment:compositionTrackSegment
                                           composition:composition
                                         compositionID:compositionID
                           compositionTrackSegmentName:compositionTrackSegmentName
                                         renderCaption:nil
                                          renderEffect:nil] autorelease];
}

+ (EditorTrackItemModel *)captionItemModelWithRenderCaption:(SVEditorRenderCaption *)renderCaption composition:(AVComposition *)composition {
    return [[[EditorTrackItemModel alloc] initWithType:EditorTrackItemModelTypeCaption
                               compositionTrackSegment:nil
                                           composition:composition
                                         compositionID:nil
                           compositionTrackSegmentName:nil
                                         renderCaption:renderCaption
                                          renderEffect:nil] autorelease];
}

+ (EditorTrackItemModel *)effectItemModelWithRenderEffect:(SVEditorRenderEffect *)renderEffect composition:(AVComposition *)composition {
    return [[[EditorTrackItemModel alloc] initWithType:EditorTrackItemModelTypeEffect
                               compositionTrackSegment:nil
                                           composition:composition
                                         compositionID:nil
                           compositionTrackSegmentName:nil
                                         renderCaption:nil
                                          renderEffect:renderEffect] autorelease];
}

- (instancetype)initWithType:(EditorTrackItemModelType)type 
     compositionTrackSegment:(AVCompositionTrackSegment * _Nullable)compositionTrackSegment
                 composition:(AVComposition *)composition
               compositionID:(NSUUID *)compositionID 
 compositionTrackSegmentName:(NSString * _Nullable)compositionTrackSegmentName
               renderCaption:(SVEditorRenderCaption * _Nullable)renderCaption
               renderEffect:(SVEditorRenderEffect * _Nullable)renderEffect __attribute__((objc_direct)) {
    if (self = [super init]) {
        _type = type;
        _compositionTrackSegment = [compositionTrackSegment retain];
        _composition = [composition retain];
        _compositionID = [compositionID copy];
        _compositionTrackSegmentName = [compositionTrackSegmentName copy];
        _renderCaption = [renderCaption retain];
        _renderEffect = [renderEffect retain];
    }
    
    return self;
}

- (void)dealloc {
    [_compositionTrackSegment release];
    [_composition release];
    [_compositionID release];
    [_compositionTrackSegmentName release];
    [_renderCaption release];
    [_renderEffect release];
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
        [_renderCaption.captionID isEqual:object->_renderCaption.captionID] &&
        [_renderEffect.effectID isEqual:object->_renderEffect.effectID];
    }
}

- (NSUInteger)hash {
    return _type ^
    _compositionTrackSegment.hash ^
    _compositionID.hash ^
    _compositionTrackSegmentName.hash ^
    _renderCaption.hash ^
    _renderEffect.hash;
}

@end
