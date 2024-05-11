//
//  EditorPlayerViewController.mm
//  SurfVideo_AppKit
//
//  Created by Jinwoo Kim on 5/11/24.
//

#import "EditorPlayerViewController.hpp"
#import <AVKit/AVKit.h>

__attribute__((objc_direct_members))
@interface EditorPlayerViewController ()
@property (retain, readonly, nonatomic) AVPlayerView *playerView;
@end

@implementation EditorPlayerViewController

@synthesize playerView = _playerView;

- (void)dealloc {
    [_playerView release];
    [super dealloc];
}

- (void)loadView {
    self.view = self.playerView;
}

- (AVPlayer *)player {
    return self.playerView.player;
}

- (void)setPlayer:(AVPlayer *)player {
    self.playerView.player = player;
}

- (AVPlayerView *)playerView {
    if (auto playerView = _playerView) return playerView;
    
    AVPlayerView *playerView = [AVPlayerView new];
    playerView.videoGravity = AVLayerVideoGravityResizeAspect;
    playerView.allowsMagnification = YES;
    
    _playerView = [playerView retain];
    return [playerView autorelease];
}

@end
