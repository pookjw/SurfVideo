//
//  EditorViewVisualProvider.hpp
//  SurfVideo
//
//  Created by Jinwoo Kim on 5/4/24.
//

#import <UIKit/UIKit.h>
#import "EditorViewController.hpp"
#import <PhotosUI/PhotosUI.h>

NS_ASSUME_NONNULL_BEGIN

@class EditorViewVisualProvider;
@protocol EditorViewVisualProviderDelegate <NSObject>
- (void)editorViewVisualProvider:(EditorViewVisualProvider *)editorViewVisualProvider didFinishPickingPickerResultsForAddingVideoClip:(NSArray<PHPickerResult *> *)pickerResults;

- (void)didSelectPhotoPickerForAddingVideoClipWithEditorViewVisualProvider:(EditorViewVisualProvider *)editorViewVisualProvider;

- (void)didSelectDocumentBrowserForAddingVideoClipWithEditorViewVisualProvider:(EditorViewVisualProvider *)editorViewVisualProvider;

- (void)didSelectPhotoPickerForAddingAudioClipWithEditorViewVisualProvider:(EditorViewVisualProvider *)editorViewVisualProvider;

- (void)didSelectDocumentBrowserForAddingAudioClipWithEditorViewVisualProvider:(EditorViewVisualProvider *)editorViewVisualProvider;

- (void)didSelectAddCaptionWithEditorViewVisualProvider:(EditorViewVisualProvider *)editorViewVisualProvider;

- (void)editorViewVisualProvider:(EditorViewVisualProvider *)editorViewVisualProvider didSelectExportWithQuality:(EditorServiceExportQuality)exportQuality;
@end

@interface EditorViewVisualProvider : NSObject
@property (weak, nonatomic, direct) id<EditorViewVisualProviderDelegate> delegate;
@property (weak, readonly, nonatomic, direct) EditorViewController * _Nullable editorViewController;
@property (readonly, nonatomic, direct) EditorPlayerViewController * _Nullable playerViewController;
@property (readonly, nonatomic, direct) EditorTrackViewController * _Nullable trackViewController;
@property (readonly, nonatomic, direct) SVEditorService * _Nullable editorService;
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithEditorViewController:(EditorViewController *)editorViewController NS_DESIGNATED_INITIALIZER;
- (void)editorViewController_viewDidLoad;
@end

NS_ASSUME_NONNULL_END
