//
//  EditorPlayerViewController.hpp
//  SurfVideo_AppKit
//
//  Created by Jinwoo Kim on 5/11/24.
//

#import <Cocoa/Cocoa.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@class EditorPlayerViewController;
@protocol EditorPlayerViewControllerDelegate <NSObject>
- (void)editorPlayerViewController:(EditorPlayerViewController *)editorPlayerViewController didChangeCurrentTime:(CMTime)currentTime;
@end

__attribute__((objc_direct_members))
@interface EditorPlayerViewController : NSViewController
@property (weak) id<EditorPlayerViewControllerDelegate> delegate;
@property (retain, nonatomic) AVPlayer * _Nullable player;
@end

NS_ASSUME_NONNULL_END
