//
//  EditorTrackItemModel.hpp
//  SurfVideo
//
//  Created by Jinwoo Kim on 12/14/23.
//

#import <AVFoundation/AVFoundation.h>
#import <SurfVideoCore/SVEditorRenderCaption.hpp>
#import <SurfVideoCore/SVEditorRenderEffect.hpp>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, EditorTrackItemModelType) {
    EditorTrackItemModelTypeVideoTrackSegment,
    EditorTrackItemModelTypeAudioTrackSegment,
    EditorTrackItemModelTypeCaption,
    EditorTrackItemModelTypeEffect
};

@interface EditorTrackItemModel : NSObject
@property (assign, readonly, nonatomic) EditorTrackItemModelType type;
@property (retain, readonly, nonatomic) AVCompositionTrackSegment * _Nullable compositionTrackSegment;
@property (retain, readonly, nonatomic) AVComposition * _Nullable composition;
@property (copy, readonly, nonatomic) NSUUID * _Nullable compositionID;
@property (copy, readonly, nonatomic) NSString * _Nullable compositionTrackSegmentName;
@property (retain, readonly, nonatomic) SVEditorRenderCaption * _Nullable renderCaption;
@property (retain, readonly, nonatomic) SVEditorRenderEffect * _Nullable renderEffect;
+ (EditorTrackItemModel *)videoTrackSegmentItemModelWithCompositionTrackSegment:(AVCompositionTrackSegment *)compositionTrackSegment composition:(AVComposition *)composition compositionID:(NSUUID *)compositionID compositionTrackSegmentName:(NSString *)compositionTrackSegmentName;
+ (EditorTrackItemModel *)audioTrackSegmentItemModelWithCompositionTrackSegment:(AVCompositionTrackSegment *)compositionTrackSegment composition:(AVComposition *)composition compositionID:(NSUUID *)compositionID compositionTrackSegmentName:(NSString *)compositionTrackSegmentName;
+ (EditorTrackItemModel *)captionItemModelWithRenderCaption:(SVEditorRenderCaption *)renderCaption composition:(AVComposition *)composition;
+ (EditorTrackItemModel *)effectItemModelWithRenderEffect:(SVEditorRenderEffect *)renderEffect composition:(AVComposition *)composition;
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
@end

NS_ASSUME_NONNULL_END
