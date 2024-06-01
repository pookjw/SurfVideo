//
//  EditorImmersiveEffectPickerItemModel.hpp
//  SurfVideo_UIKit
//
//  Created by Jinwoo Kim on 6/1/24.
//

#import <TargetConditionals.h>

#if TARGET_OS_VISION

#import <Foundation/Foundation.h>
#import "ImmersiveEffect.hpp"

NS_ASSUME_NONNULL_BEGIN

__attribute__((objc_direct_members))
@interface EditorImmersiveEffectPickerItemModel : NSObject
@property (assign, readonly, nonatomic) ImmersiveEffect effect;
@property (readonly, nonatomic) NSString *title;
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithEffect:(ImmersiveEffect)effect;
@end

NS_ASSUME_NONNULL_END

#endif
