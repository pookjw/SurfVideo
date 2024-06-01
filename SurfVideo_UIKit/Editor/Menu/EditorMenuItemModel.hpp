//
//  EditorMenuItemModel.hpp
//  SurfVideo
//
//  Created by Jinwoo Kim on 2/23/24.
//

#import <UIKit/UIKit.h>
#import <TargetConditionals.h>

#if TARGET_OS_VISION

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, EditorMenuItemModelType) {
    EditorMenuItemModelTypeAddVideoClips,
    EditorMenuItemModelTypeAddAudioClips,
    EditorMenuItemModelTypeAddCaption,
    EditorMenuItemModelTypeAddEffect
};

__attribute__((objc_direct_members))
@interface EditorMenuItemModel : NSObject
@property (assign, nonatomic, readonly) EditorMenuItemModelType type;
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithType:(EditorMenuItemModelType)type NS_DESIGNATED_INITIALIZER;
@end

NS_ASSUME_NONNULL_END

#endif
