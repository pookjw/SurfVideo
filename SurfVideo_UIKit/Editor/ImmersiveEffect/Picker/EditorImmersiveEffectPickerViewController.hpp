//
//  EditorImmersiveEffectPickerViewController.hpp
//  SurfVideo_UIKit
//
//  Created by Jinwoo Kim on 6/1/24.
//

#import <TargetConditionals.h>

#if TARGET_OS_VISION

#import <UIKit/UIKit.h>
#import "ImmersiveEffect.hpp"

NS_ASSUME_NONNULL_BEGIN

@class EditorImmersiveEffectPickerViewController;
@protocol EditorImmersiveEffectPickerViewControllerDelegate <NSObject>
- (void)editorImmersiveEffectPickerViewController:(EditorImmersiveEffectPickerViewController *)editorImmersiveEffectPickerViewController didAddImmersiveEffect:(ImmersiveEffect)immersiveEffect;
@end

__attribute__((objc_direct_members))
@interface EditorImmersiveEffectPickerViewController : UICollectionViewController
@property (weak, nonatomic) id<EditorImmersiveEffectPickerViewControllerDelegate> delegate;
@end

NS_ASSUME_NONNULL_END

#endif
