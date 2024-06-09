//
//  EditorMenuCollectionViewLayout.hpp
//  SurfVideo
//
//  Created by Jinwoo Kim on 2/23/24.
//

#import <TargetConditionals.h>

#if TARGET_OS_VISION

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

//__attribute__((objc_direct_members))
@interface EditorMenuCollectionViewLayout : UICollectionViewCompositionalLayout
+ (instancetype)new;
- (instancetype)init;
@end

NS_ASSUME_NONNULL_END

#endif
