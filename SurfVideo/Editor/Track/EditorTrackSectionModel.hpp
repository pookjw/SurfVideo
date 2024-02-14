//
//  EditorTrackSectionModel.hpp
//  SurfVideo
//
//  Created by Jinwoo Kim on 12/14/23.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, EditorTrackSectionModelType) {
    EditorTrackSectionModelTypeMainVideoTrack
};

// AVCompositionTrack *
extern NSString * const EditorTrackSectionModelCompositionTrackKey;

__attribute__((objc_direct_members))
@interface EditorTrackSectionModel : NSObject
@property (assign, nonatomic, readonly) EditorTrackSectionModelType type;
@property (copy) NSDictionary<NSString *, id> * _Nullable userInfo;
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithType:(EditorTrackSectionModelType)type NS_DESIGNATED_INITIALIZER;
@end

NS_ASSUME_NONNULL_END
