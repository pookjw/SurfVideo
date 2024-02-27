//
//  EditorPlayerViewController.hpp
//  SurfVideo
//
//  Created by Jinwoo Kim on 2/28/24.
//

#import <UIKit/UIKit.h>
#import <AVKit/AVKit.h>

NS_ASSUME_NONNULL_BEGIN

@class EditorPlayerViewController;
@protocol EditorPlayerViewControllerDelegate <NSObject>
- (void)editorPlayerViewController:(EditorPlayerViewController *)editorPlayerViewController didChangeCurrentTime:(CMTime)currentTime;
@end

__attribute__((objc_direct_members))
@interface EditorPlayerViewController : UIViewController
@property (weak) id<EditorPlayerViewControllerDelegate> delegate;
@property (retain, nonatomic) AVPlayer * _Nullable player;
@end

NS_ASSUME_NONNULL_END
