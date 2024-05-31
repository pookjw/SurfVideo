//
//  ImmersiveEffectPickerViewController.hpp
//  SurfVideo_UIKit
//
//  Created by Jinwoo Kim on 6/1/24.
//

#import <UIKit/UIKit.h>
#import <TargetConditionals.h>

#if TARGET_OS_VISION

NS_ASSUME_NONNULL_BEGIN

__attribute__((objc_direct_members))
@interface ImmersiveEffectPickerViewController : UICollectionViewController
@end

NS_ASSUME_NONNULL_END

#endif
