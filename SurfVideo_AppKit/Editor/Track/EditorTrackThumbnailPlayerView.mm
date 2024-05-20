//
//  EditorTrackThumbnailPlayerView.mm
//  SurfVideo_AppKit
//
//  Created by Jinwoo Kim on 5/17/24.
//

#import "EditorTrackThumbnailPlayerView.hpp"
#import "EditorTrackCollectionViewLayoutAttributes.hpp"

__attribute__((objc_direct_members))
@interface EditorTrackThumbnailPlayerView ()
@property (readonly) AVPlayerLayer *playerLayer;
@property (retain, readonly, nonatomic) AVPlayer *player;
@end

@implementation EditorTrackThumbnailPlayerView
@synthesize player = _player;

+ (NSUserInterfaceItemIdentifier)reuseIdentifier {
    return @"EditorTrackThumbnailPlayerView";
}

- (instancetype)initWithFrame:(NSRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self commonInit_EditorTrackThumbnailPlayerView];
    }
    
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    if (self = [super initWithCoder:coder]) {
        [self commonInit_EditorTrackThumbnailPlayerView];
    }
    
    return self;
}

- (void)dealloc {
    [_player release];
    [super dealloc];
}

- (void)commonInit_EditorTrackThumbnailPlayerView __attribute__((objc_direct)) {
    AVPlayerLayer *playerLayer = [AVPlayerLayer new];
    self.layer = playerLayer;
    [playerLayer release];
    
    self.wantsLayer = YES;
}

- (AVPlayerLayer *)playerLayer {
    return (AVPlayerLayer *)self.layer;
}

@end
