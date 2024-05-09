//
//  EditorTrackItemModel.hpp
//  SurfVideo
//
//  Created by Jinwoo Kim on 12/14/23.
//

#import <AVFoundation/AVFoundation.h>
#import <SurfVideoCore/EditorRenderCaption.hpp>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, EditorTrackItemModelType) {
    EditorTrackItemModelTypeVideoTrackSegment,
    EditorTrackItemModelTypeAudioTrackSegment,
    EditorTrackItemModelTypeCaption
};

__attribute__((objc_direct_members))
@interface EditorTrackItemModel : NSObject
@property (assign, readonly, nonatomic) EditorTrackItemModelType type;
@property (retain, readonly, nonatomic) AVCompositionTrackSegment * _Nullable compositionTrackSegment;
@property (retain, readonly, nonatomic) AVComposition * _Nullable composition;
@property (retain, readonly, nonatomic) AVVideoComposition * _Nullable videoComposition;
@property (copy, readonly, nonatomic) NSUUID * _Nullable compositionID;
@property (copy, readonly, nonatomic) NSString * _Nullable compositionTrackSegmentName;
@property (retain, readonly, nonatomic) EditorRenderCaption *renderCaption;
+ (EditorTrackItemModel *)videoTrackSegmentItemModelWithCompositionTrackSegment:(AVCompositionTrackSegment *)compositionTrackSegment composition:(AVComposition *)composition videoComposition:(AVVideoComposition *)videoComposition compositionID:(NSUUID *)compositionID compositionTrackSegmentName:(NSString *)compositionTrackSegmentName;
+ (EditorTrackItemModel *)audioTrackSegmentItemModelWithCompositionTrackSegment:(AVCompositionTrackSegment *)compositionTrackSegment composition:(AVComposition *)composition videoComposition:(AVVideoComposition *)videoComposition compositionID:(NSUUID *)compositionID compositionTrackSegmentName:(NSString *)compositionTrackSegmentName;
+ (EditorTrackItemModel *)captionItemModelWithRenderCaption:(EditorRenderCaption *)renderCaption composition:(AVComposition *)composition videoComposition:(AVVideoComposition *)videoComposition;
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
@end

NS_ASSUME_NONNULL_END
