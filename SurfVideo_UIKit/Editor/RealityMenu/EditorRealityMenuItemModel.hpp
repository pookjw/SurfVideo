//
//  EditorRealityMenuItemModel.hpp
//  SurfVideo_UIKit
//
//  Created by Jinwoo Kim on 6/9/24.
//

#import <TargetConditionals.h>

#if TARGET_OS_VISION

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, EditorRealityMenuItemModelType) {
    EditorRealityMenuItemModelTypeImmersiveSpace,
    EditorRealityMenuItemModelTypeScrollTrackViewWithHandTracking
};

__attribute__((objc_direct_members))
@interface EditorRealityMenuItemModel : NSObject
@property (assign, readonly, nonatomic) EditorRealityMenuItemModelType type;
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithType:(EditorRealityMenuItemModelType)type;
@end

NS_ASSUME_NONNULL_END

#endif
