//
//  EditorMenuViewController.hpp
//  SurfVideo
//
//  Created by Jinwoo Kim on 12/3/23.
//

#import <TargetConditionals.h>

#if TARGET_OS_VISION

#import <UIKit/UIKit.h>
#import <SurfVideoCore/SVEditorService.hpp>
#import <SurfVideoCore/EditorTrackItemModel.hpp>

NS_ASSUME_NONNULL_BEGIN

@class EditorMenuViewController;
@protocol EditorMenuViewControllerDelegate <NSObject>
- (void)editorMenuViewControllerDidSelectAddCaption:(EditorMenuViewController *)viewController;
- (void)editorMenuViewControllerDidSelectAddEffect:(EditorMenuViewController *)viewController;
- (void)editorMenuViewControllerDidSelectAddVideoClipsWithPhotoPicker:(EditorMenuViewController *)viewController;
- (void)editorMenuViewControllerDidSelectAddVideoClipsWithDocumentBrowser:(EditorMenuViewController *)viewController;
- (void)editorMenuViewControllerDidSelectAddAudioClipsWithPhotoPicker:(EditorMenuViewController *)viewController;
- (void)editorMenuViewControllerDidSelectAddAudioClipsWithDocumentBrowser:(EditorMenuViewController *)viewController;
@end

__attribute__((objc_direct_members))
@interface EditorMenuViewController : UIViewController
@property (weak) id<EditorMenuViewControllerDelegate> delegate;
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithNibName:(nullable NSString *)nibNameOrNil bundle:(nullable NSBundle *)nibBundleOrNil NS_UNAVAILABLE;
- (nullable instancetype)initWithCoder:(NSCoder *)coder NS_UNAVAILABLE;
- (instancetype)initWithEditorService:(SVEditorService *)editorService;
@end

NS_ASSUME_NONNULL_END

#endif
