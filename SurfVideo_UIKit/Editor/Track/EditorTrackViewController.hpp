//
//  EditorTrackViewController.hpp
//  SurfVideo
//
//  Created by Jinwoo Kim on 12/13/23.
//

#import <UIKit/UIKit.h>
#import <CoreMedia/CoreMedia.h>
#import <SurfVideoCore/SVEditorService.hpp>

NS_ASSUME_NONNULL_BEGIN

@class EditorTrackViewController;
@protocol EditorTrackViewControllerDelegate <NSObject>
- (void)editorTrackViewController:(EditorTrackViewController *)viewController willBeginScrollingWithCurrentTime:(CMTime)currentTime;
- (void)editorTrackViewController:(EditorTrackViewController *)viewController scrollingWithCurrentTime:(CMTime)currentTime;
- (void)editorTrackViewController:(EditorTrackViewController *)viewController didEndScrollingWithCurrentTime:(CMTime)currentTime;
@end

__attribute__((objc_direct_members))
@interface EditorTrackViewController : UIViewController
@property (retain, readonly, nonatomic) UICollectionView *collectionViewIfLoaded;
@property (weak) id<EditorTrackViewControllerDelegate> delegate;
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithNibName:(nullable NSString *)nibNameOrNil bundle:(nullable NSBundle *)nibBundleOrNil NS_UNAVAILABLE;
- (nullable instancetype)initWithCoder:(NSCoder *)coder NS_UNAVAILABLE;
- (instancetype)initWithEditorService:(SVEditorService *)editorService;
- (void)updateCurrentTime:(CMTime)currentTime;
@end

NS_ASSUME_NONNULL_END
