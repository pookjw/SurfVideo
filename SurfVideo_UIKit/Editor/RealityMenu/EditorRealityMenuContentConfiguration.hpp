//
//  EditorRealityMenuContentConfiguration.hpp
//  SurfVideo_UIKit
//
//  Created by Jinwoo Kim on 6/9/24.
//

#import <TargetConditionals.h>

#if TARGET_OS_VISION

#import <UIKit/UIKit.h>
#import "EditorRealityMenuItemModel.hpp"

NS_ASSUME_NONNULL_BEGIN

__attribute__((objc_direct_members))
@interface EditorRealityMenuContentConfiguration : NSObject <UIContentConfiguration>
@property (retain, readonly, nonatomic) EditorRealityMenuItemModel *itemModel;
@property (assign, readonly, nonatomic, getter=isSelected) BOOL selected;
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithItemModel:(EditorRealityMenuItemModel *)itemModel selected:(BOOL)selected NS_DESIGNATED_INITIALIZER;
@end

NS_ASSUME_NONNULL_END

#endif
