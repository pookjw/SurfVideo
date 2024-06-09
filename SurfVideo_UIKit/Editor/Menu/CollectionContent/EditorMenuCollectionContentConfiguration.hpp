//
//  EditorMenuCollectionContentConfiguration.hpp
//  SurfVideo
//
//  Created by Jinwoo Kim on 2/27/24.
//

#import <TargetConditionals.h>

#if TARGET_OS_VISION

#import <UIKit/UIKit.h>
#import "EditorMenuItemModel.hpp"

NS_ASSUME_NONNULL_BEGIN

@class EditorMenuCollectionContentConfiguration;
@protocol EditorMenuCollectionContentConfigurationDelegate <NSObject>
- (void)editorMenuCollectionContentConfigurationDidSelectAddCaption:(EditorMenuCollectionContentConfiguration *)contentConfiguration;
- (void)editorMenuCollectionContentConfigurationDidSelectAddEffect:(EditorMenuCollectionContentConfiguration *)contentConfiguration;
- (void)editorMenuCollectionContentConfigurationDidSelectAddVideoClipsWithPhotoPicker:(EditorMenuCollectionContentConfiguration *)contentConfiguration;
- (void)editorMenuCollectionContentConfigurationDidSelectAddVideoClipsWithDocumentBrowser:(EditorMenuCollectionContentConfiguration *)contentConfiguration;
- (void)editorMenuCollectionContentConfigurationDidSelectAddAudioClipsWithPhotoPicker:(EditorMenuCollectionContentConfiguration *)contentConfiguration;
- (void)editorMenuCollectionContentConfigurationDidSelectAddAudioClipsWithDocumentBrowser:(EditorMenuCollectionContentConfiguration *)contentConfiguration;
@end

__attribute__((objc_direct_members))
@interface EditorMenuCollectionContentConfiguration : NSObject <UIContentConfiguration>
@property (assign, readonly, nonatomic) EditorMenuItemModelType type;
@property (weak) id<EditorMenuCollectionContentConfigurationDelegate> delegate;
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithType:(EditorMenuItemModelType)type NS_DESIGNATED_INITIALIZER;
@end

NS_ASSUME_NONNULL_END

#endif
