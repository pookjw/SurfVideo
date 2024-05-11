//
//  EditorPlayerViewVisualProviderIOS.mm
//  SurfVideo
//
//  Created by Jinwoo Kim on 5/7/24.
//

#import "EditorPlayerViewVisualProviderIOS.hpp"
#import <AVKit/AVKit.h>

#if TARGET_OS_IOS

__attribute__((objc_direct_members))
@interface EditorPlayerViewVisualProviderIOS ()
@property (retain, readonly) AVPlayerViewController *avPlayerViewController;
@end

@implementation EditorPlayerViewVisualProviderIOS

@synthesize avPlayerViewController = _avPlayerViewController;

- (void)dealloc {
    [_avPlayerViewController release];
    [super dealloc];
}

- (void)playerViewController_viewDidLoad {
    EditorPlayerViewController *playerViewController = self.playerViewController;
    UIView *containerView = playerViewController.view;
    AVPlayerViewController *avPlayerViewController = self.avPlayerViewController;
    UIView *avPlayerView = avPlayerViewController.view;
    
    [playerViewController addChildViewController:avPlayerViewController];
    avPlayerView.frame = containerView.bounds;
    avPlayerView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [containerView addSubview:avPlayerView];
    [avPlayerViewController didMoveToParentViewController:playerViewController];
}

- (void)setPlayer:(AVPlayer *)player {
    self.avPlayerViewController.player = player;
}

- (AVPlayer *)player {
    return self.avPlayerViewController.player;
}

- (AVPlayerViewController *)avPlayerViewController {
    if (auto avPlayerViewController = _avPlayerViewController) return avPlayerViewController;
    
    AVPlayerViewController *avPlayerViewController = [AVPlayerViewController new];
    
    _avPlayerViewController = [avPlayerViewController retain];
    return [avPlayerViewController autorelease];
}

@end

#endif
