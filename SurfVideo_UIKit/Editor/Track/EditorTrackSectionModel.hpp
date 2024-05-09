//
//  EditorTrackSectionModel.hpp
//  SurfVideo
//
//  Created by Jinwoo Kim on 12/14/23.
//

#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, EditorTrackSectionModelType) {
    EditorTrackSectionModelTypeMainVideoTrack,
    EditorTrackSectionModelTypeAudioTrack,
    EditorTrackSectionModelTypeCaptionTrack
};

__attribute__((objc_direct_members))
@interface EditorTrackSectionModel : NSObject
@property (assign, nonatomic, readonly) EditorTrackSectionModelType type;
@property (copy, readonly, nonatomic) AVComposition *composition;
@property (copy, readonly, nonatomic) AVCompositionTrack * _Nullable compositionTrack;
+ (EditorTrackSectionModel *)mainVideoTrackSectionModelWithComposition:(AVComposition *)composotion compositionTrack:(AVCompositionTrack *)compositionTrack;
+ (EditorTrackSectionModel *)audioTrackSectionModelWithComposition:(AVComposition *)composotion compositionTrack:(AVCompositionTrack *)compositionTrack;
+ (EditorTrackSectionModel *)captionTrackSectionModelWithComposition:(AVComposition *)composotion;
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
@end

NS_ASSUME_NONNULL_END
