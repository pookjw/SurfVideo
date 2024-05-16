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
@property (retain, nonatomic) id _Nullable timeObserverToken;
@end

@implementation EditorPlayerViewController

@synthesize playerView = _playerView;

- (void)dealloc {
    if (AVPlayerView *playerView = _playerView) {
        if (id timeObserverToken = _timeObserverToken) {
            if (AVPlayer *player = playerView.player) {
                [player removeTimeObserver:timeObserverToken];
            }
        }
        
        [playerView release];
    }
    
    [_timeObserverToken release];
    
    [super dealloc];
}

- (void)loadView {
    self.view = self.playerView;
}

- (AVPlayer *)player {
    return self.playerView.player;
}

- (void)setPlayer:(AVPlayer *)player {
    AVPlayerView *playerView = self.playerView;
    
    if (AVPlayer *oldPlayer = playerView.player) {
        if (id timeObserverToken = self.timeObserverToken) {
            [oldPlayer removeTimeObserver:timeObserverToken];
        }
    }
    
    playerView.player = player;
    
    __weak auto weakSelf = self;
    
    self.timeObserverToken = [player addPeriodicTimeObserverForInterval:CMTimeMake(1, 60) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
        auto unwrapped = weakSelf;
        if (unwrapped == nil) return;
        
        auto delegate = unwrapped.delegate;
        if (delegate != nil) {
            [delegate editorPlayerViewController:unwrapped didChangeCurrentTime:time];
        }
    }];
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
