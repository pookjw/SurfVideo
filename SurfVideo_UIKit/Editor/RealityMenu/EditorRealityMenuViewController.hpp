//
//  EditorRealityMenuViewController.hpp
//  SurfVideo_UIKit
//
//  Created by Jinwoo Kim on 6/8/24.
//

#import <TargetConditionals.h>

#if TARGET_OS_VISION

#import <UIKit/UIKit.h>
#import "EditorRealityMenuItemModel.hpp"

NS_ASSUME_NONNULL_BEGIN

@class EditorRealityMenuViewController;
@protocol EditorRealityMenuViewControllerDelegate <NSObject>
- (void)editorRealityMenuViewController:(EditorRealityMenuViewController *)editorRealityMenuViewController didToggleScrollingTrackViewWithHandTracking:(BOOL)enabled;
@end

__attribute__((objc_direct_members))
@interface EditorRealityMenuViewController : UIViewController
@property (weak, nonatomic) id<EditorRealityMenuViewControllerDelegate> delegate;
@end

NS_ASSUME_NONNULL_END

#endif
