//
//  EditorRealityMenuContnetView.hpp
//  SurfVideo_UIKit
//
//  Created by Jinwoo Kim on 6/9/24.
//

#import <TargetConditionals.h>

#if TARGET_OS_VISION

#import <UIKit/UIKit.h>
#import "EditorRealityMenuContentConfiguration.hpp"

NS_ASSUME_NONNULL_BEGIN

__attribute__((objc_direct_members))
@interface EditorRealityMenuContnetView : UIView <UIContentView>
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithFrame:(CGRect)frame NS_UNAVAILABLE;
- (nullable instancetype)initWithCoder:(NSCoder *)coder NS_UNAVAILABLE;
- (instancetype)initWithContentConfiguration:(EditorRealityMenuContentConfiguration *)contentConfiguration;
@end

NS_ASSUME_NONNULL_END

#endif
