//
//  EditorMenuCollectionContentView.hpp
//  SurfVideo
//
//  Created by Jinwoo Kim on 2/27/24.
//

#import <UIKit/UIKit.h>
#import "EditorMenuCollectionContentConfiguration.hpp"
#import <TargetConditionals.h>

#if TARGET_OS_VISION

NS_ASSUME_NONNULL_BEGIN

__attribute__((objc_direct_members))
@interface EditorMenuCollectionContentView : UIView <UIContentView>
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithFrame:(CGRect)frame NS_UNAVAILABLE;
- (nullable instancetype)initWithCoder:(NSCoder *)coder NS_UNAVAILABLE;
- (instancetype)initWithContentConfiguration:(EditorMenuCollectionContentConfiguration *)contentConfiguration NS_DESIGNATED_INITIALIZER;
@end

NS_ASSUME_NONNULL_END

#endif
