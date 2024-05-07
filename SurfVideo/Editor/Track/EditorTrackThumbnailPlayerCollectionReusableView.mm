//
//  EditorTrackThumbnailPlayerCollectionReusableView.mm
//  SurfVideo
//
//  Created by Jinwoo Kim on 4/25/24.
//

#import "EditorTrackThumbnailPlayerCollectionReusableView.hpp"
#import "EditorTrackCollectionViewLayoutAttributes.hpp"
#import "SVRunLoop.hpp"

__attribute__((objc_direct_members))
@interface EditorTrackThumbnailPlayerCollectionReusableView ()
@property (assign, readonly) AVPlayerLayer *playerLayer;
@property (retain, readonly, nonatomic) AVPlayer *player;
@end

@implementation EditorTrackThumbnailPlayerCollectionReusableView
@synthesize player = _player;

+ (NSString *)elementKind {
    return @"EditorTrackThumbnailPlayerCollectionReusableView";
}

+ (Class)layerClass {
    return [AVPlayerLayer class];
}

- (void)applyLayoutAttributes:(UICollectionViewLayoutAttributes *)layoutAttributes {
    [super applyLayoutAttributes:layoutAttributes];
    
    if ([layoutAttributes isKindOfClass:[EditorTrackCollectionViewLayoutAttributes class]]) {
        auto ownLayoutAttributes = static_cast<EditorTrackCollectionViewLayoutAttributes *>(layoutAttributes);
        
        AVAsset *avAsset = ownLayoutAttributes.assetResolver();
        CMTime time = ownLayoutAttributes.timeResolver();
        
        [self updateWithAVAsset:avAsset time:time];
    }
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        AVPlayerLayer *playerLayer = self.playerLayer;
        
        playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;;
        playerLayer.player = self.player;
    }
    
    return self;
}

- (void)dealloc {
    [_player release];
    [super dealloc];
}

- (AVPlayerLayer *)playerLayer {
    return (AVPlayerLayer *)self.layer;
}

- (void)updateWithAVAsset:(AVAsset *)avAsset time:(CMTime)time {
    AVPlayer *player = self.player;
    
    if (![player.currentItem.asset isEqual:avAsset]) {
        AVPlayerItem *playerItem = [[AVPlayerItem alloc] initWithAsset:avAsset];
        [player replaceCurrentItemWithPlayerItem:playerItem];
        [playerItem release];
    }
    
    
    [SVRunLoop.globalRenderRunLoop runBlock:^{
        [player seekToTime:time];
//        [player seekToTime:time toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
    }];
}

- (AVPlayer *)player {
    if (auto player = _player) return player;
    
    AVPlayer *player = [[AVPlayer alloc] initWithPlayerItem:nil];
    player.volume = 0.f;
    
    _player = [player retain];
    return [player autorelease];
}

@end
