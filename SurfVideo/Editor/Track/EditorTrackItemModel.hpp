//
//  EditorTrackItemModel.hpp
//  SurfVideo
//
//  Created by Jinwoo Kim on 12/14/23.
//

#import <Foundation/Foundation.h>
#import "EditorRenderCaption.hpp"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, EditorTrackItemModelType) {
    EditorTrackItemModelTypeVideoTrackSegment,
    EditorTrackItemModelTypeAudioTrackSegment,
    EditorTrackItemModelTypeCaption
};

// AVCompositionTrackSegment *
extern NSString * const EditorTrackItemModelCompositionTrackSegmentKey;

// NSString *
extern NSString * const EditorTrackItemModelTrackSegmentNameKey;

// EditorRenderCaption *
extern NSString * const EditorTrackItemModelRenderCaptionKey;

__attribute__((objc_direct_members))
@interface EditorTrackItemModel : NSObject
@property (assign, nonatomic, readonly) EditorTrackItemModelType type;
@property (copy) NSDictionary<NSString *, id> * _Nullable userInfo; // TODO: Thread 문제로 인해 readonly가 되어야 함. 굳이 userInfo 써야할까... 그냥 property
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithType:(EditorTrackItemModelType)type NS_DESIGNATED_INITIALIZER;
@end

NS_ASSUME_NONNULL_END
