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
    EditorTrackItemModelTypeCaption
};

// AVCompositionTrackSegment *
extern NSString * const EditorTrackItemModelCompositionTrackSegmentKey;

// EditorRenderCaption *
extern NSString * const EditorTrackItemModelRenderCaptionKey;

__attribute__((objc_direct_members))
@interface EditorTrackItemModel : NSObject
@property (assign, nonatomic, readonly) EditorTrackItemModelType type;
@property (copy) NSDictionary<NSString *, id> * _Nullable userInfo;
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithType:(EditorTrackItemModelType)type NS_DESIGNATED_INITIALIZER;
@end

NS_ASSUME_NONNULL_END
