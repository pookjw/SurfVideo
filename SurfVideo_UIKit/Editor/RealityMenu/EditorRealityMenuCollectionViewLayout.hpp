//
//  EditorRealityMenuCollectionViewLayout.hpp
//  SurfVideo_UIKit
//
//  Created by Jinwoo Kim on 6/9/24.
//

#import <TargetConditionals.h>

#if TARGET_OS_VISION

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface EditorRealityMenuCollectionViewLayout : UICollectionViewCompositionalLayout
+ (instancetype)new;
- (instancetype)init;
@end

NS_ASSUME_NONNULL_END

#endif
