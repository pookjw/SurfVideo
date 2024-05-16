//
//  EditorTrackViewController.hpp
//  SurfVideo_AppKit
//
//  Created by Jinwoo Kim on 5/11/24.
//

#import <Cocoa/Cocoa.h>
#import <SurfVideoCore/SVEditorService.hpp>
#import <CoreMedia/CoreMedia.h>

NS_ASSUME_NONNULL_BEGIN

@class EditorTrackViewController;
@protocol EditorTrackViewControllerDelegate <NSObject>
- (void)editorTrackViewController:(EditorTrackViewController *)viewController willBeginScrollingWithCurrentTime:(CMTime)currentTime;
- (void)editorTrackViewController:(EditorTrackViewController *)viewController scrollingWithCurrentTime:(CMTime)currentTime;
- (void)editorTrackViewController:(EditorTrackViewController *)viewController didEndScrollingWithCurrentTime:(CMTime)currentTime;
@end

__attribute__((objc_direct_members))
@interface EditorTrackViewController : NSViewController
@property (weak) id<EditorTrackViewControllerDelegate> delegate;
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithEditorService:(SVEditorService *)editorService;
- (void)updateCurrentTime:(CMTime)currentTime;
@end

NS_ASSUME_NONNULL_END
