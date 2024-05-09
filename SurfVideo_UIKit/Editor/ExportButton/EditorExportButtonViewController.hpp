//
//  EditorExportButtonViewController.hpp
//  SurfVideo
//
//  Created by Jinwoo Kim on 3/10/24.
//


#import <TargetConditionals.h>

#if TARGET_OS_VISION

#import <UIKit/UIKit.h>
#import <SurfVideoCore/EditorService.hpp>

NS_ASSUME_NONNULL_BEGIN

@class EditorExportButtonViewController;
@protocol EditorExportButtonViewControllerDelegate <NSObject>
- (void)editorExportButtonViewController:(EditorExportButtonViewController *)editorExportButtonViewController didTriggerButtonWithExportQuality:(EditorServiceExportQuality)exportQuality;
@end

__attribute__((objc_direct_members))
@interface EditorExportButtonViewController : UIViewController
@property (weak) id<EditorExportButtonViewControllerDelegate> delegate;
@end

NS_ASSUME_NONNULL_END

#endif
