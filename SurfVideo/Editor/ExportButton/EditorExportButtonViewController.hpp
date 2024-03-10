//
//  EditorExportButtonViewController.hpp
//  SurfVideo
//
//  Created by Jinwoo Kim on 3/10/24.
//

#import <UIKit/UIKit.h>
#import "EditorService.hpp"

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
