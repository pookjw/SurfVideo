//
//  EditorPlayerViewVisualProviderReality.mm
//  SurfVideo
//
//  Created by Jinwoo Kim on 5/7/24.
//

#import "EditorPlayerViewVisualProviderReality.hpp"
#import "UIView+SpatialEffect.hpp"
#import "UIView+Private.h"

#if TARGET_OS_VISION

__attribute__((objc_direct_members))
@interface _EditorPlayerView : UIView
@property (readonly, nonatomic) AVPlayerLayer *playerLayer;
@end

@implementation _EditorPlayerView

+ (Class)layerClass {
    return AVPlayerLayer.class;
}

- (AVPlayerLayer *)playerLayer {
    return static_cast<AVPlayerLayer *>(self.layer);
}

@end

__attribute__((objc_direct_members))
@interface EditorPlayerViewVisualProviderReality ()
@property (class, readonly, nonatomic) CMTimeScale preferredTimescale;
@property (class, readonly, nonatomic) void *statusContext;
@property (class, readonly, nonatomic) void *currentItemContext;
@property (class, readonly, nonatomic) void *durationContext;
@property (class, readonly, nonatomic) void *timeControlStatusContext;
@property (readonly, nonatomic) UIView *containerView;
@property (retain, readonly, nonatomic) _EditorPlayerView *playerView;
@property (retain, readonly, nonatomic) UIStackView *controlView;
@property (retain, readonly, nonatomic) UIButton *playbackButton;
@property (retain, readonly, nonatomic) UISlider *seekSlider;
@property (readonly, nonatomic) UIButtonConfiguration *loadingButtonConfiguration;
@property (readonly, nonatomic) UIButtonConfiguration *playButtonConfiguration;
@property (readonly, nonatomic) UIButtonConfiguration *pauseButtonConfiguration;
@property (readonly, nonatomic) UIButtonConfiguration *errorButtonConfiguration;
@end

@implementation EditorPlayerViewVisualProviderReality

@synthesize playerView = _playerView;
@synthesize controlView = _controlView;
@synthesize playbackButton = _playbackButton;
@synthesize seekSlider = _seekSlider;

+ (CMTimeScale)preferredTimescale {
    return 1000000000L;
}

+ (void *)statusContext {
    static void *statusContext = &statusContext;
    return statusContext;
}

+ (void *)currentItemContext {
    static void *currentItemContext = &currentItemContext;
    return currentItemContext;
}

+ (void *)durationContext {
    static void *durationContext = &durationContext;
    return durationContext;
}

+ (void *)timeControlStatusContext {
    static void *timeControlStatusContext = &timeControlStatusContext;
    return timeControlStatusContext;
}

- (void)dealloc {
    if (AVPlayer *player = _playerView.playerLayer.player) {
        [self removeObserverForPlayer:player];
    }
    
    [_playerView release];
    [_controlView release];
    [_playbackButton release];
    [_seekSlider release];
    [super dealloc];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if (context == EditorPlayerViewVisualProviderReality.currentItemContext) {
        [self currentItemDidChangeWithObject:object change:change];
    } else if (context == EditorPlayerViewVisualProviderReality.statusContext) {
        [self statusDidChangeWithObject:object change:change];
    } else if (context == EditorPlayerViewVisualProviderReality.timeControlStatusContext) {
        [self timeControlStatusDidChangeWithObject:object change:change];
    } else if (context == EditorPlayerViewVisualProviderReality.durationContext) {
        [self durationDidChangeWithObject:object change:change];
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void)playerViewController_viewDidLoad {
    UIView *containerView = self.containerView;
    _EditorPlayerView *playerView = self.playerView;
    UIStackView *controlView = self.controlView;
    UIButton *playbackButton = self.playbackButton;
    UISlider *seekSlider = self.seekSlider;
    
    playerView.sv_spatialEffect = YES;
    
    [playbackButton setContentHuggingPriority:UILayoutPriorityDefaultHigh forAxis:UILayoutConstraintAxisHorizontal];
    [seekSlider setContentHuggingPriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
    
    [controlView addArrangedSubview:playbackButton];
    [controlView addArrangedSubview:seekSlider];
    
    controlView.translatesAutoresizingMaskIntoConstraints = NO;
    playerView.translatesAutoresizingMaskIntoConstraints = NO;
    
    [containerView addSubview:playerView];
    [containerView addSubview:controlView];
    
    [NSLayoutConstraint activateConstraints:@[
        [playerView.topAnchor constraintEqualToAnchor:containerView.topAnchor],
        [playerView.leadingAnchor constraintEqualToAnchor:containerView.leadingAnchor],
        [playerView.trailingAnchor constraintEqualToAnchor:containerView.trailingAnchor],
        [playerView.bottomAnchor constraintEqualToAnchor:containerView.bottomAnchor],
        [controlView.leadingAnchor constraintEqualToAnchor:containerView.layoutMarginsGuide.leadingAnchor constant:20.f],
        [controlView.trailingAnchor constraintEqualToAnchor:containerView.layoutMarginsGuide.trailingAnchor constant:-20.f],
        [controlView.bottomAnchor constraintEqualToAnchor:containerView.layoutMarginsGuide.bottomAnchor],
        [controlView.centerXAnchor constraintEqualToAnchor:containerView.layoutMarginsGuide.centerXAnchor]
    ]];
}

- (void)playerCurrentTimeDidChange:(CMTime)currentTime {
    UISlider *seekSlider = self.seekSlider;
    
    if (!seekSlider.tracking) {
        seekSlider.value = CMTimeConvertScale(currentTime, EditorPlayerViewVisualProviderReality.preferredTimescale, kCMTimeRoundingMethod_RoundAwayFromZero).value;
    }
}

- (AVPlayer *)player {
    return self.playerView.playerLayer.player;
}

- (void)setPlayer:(AVPlayer *)player {
    if (AVPlayer *oldPlayer = self.player) {
        [self removeObserverForPlayer:oldPlayer];
    }
    
    [player addObserver:self forKeyPath:@"currentItem" options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew context:[EditorPlayerViewVisualProviderReality currentItemContext]];
    [player addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew context:[EditorPlayerViewVisualProviderReality statusContext]];
    [player addObserver:self forKeyPath:@"timeControlStatus" options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew context:[EditorPlayerViewVisualProviderReality timeControlStatusContext]];
    
    self.playerView.playerLayer.player = player;
}

- (void)removeObserverForPlayer:(AVPlayer *)player __attribute__((objc_direct)) {
    [player.currentItem removeObserver:self forKeyPath:@"duration" context:[EditorPlayerViewVisualProviderReality durationContext]];
    [player removeObserver:self forKeyPath:@"currentItem" context:[EditorPlayerViewVisualProviderReality currentItemContext]];
    [player removeObserver:self forKeyPath:@"status" context:[EditorPlayerViewVisualProviderReality statusContext]];
    [player removeObserver:self forKeyPath:@"timeControlStatus" context:[EditorPlayerViewVisualProviderReality timeControlStatusContext]];
}

- (void)currentItemDidChangeWithObject:(id)object change:(NSDictionary *)change __attribute__((objc_direct)) {
    if (AVPlayerItem *oldPlayerItem = change[NSKeyValueChangeOldKey]) {
        [oldPlayerItem removeObserver:self forKeyPath:@"duration" context:[EditorPlayerViewVisualProviderReality durationContext]];
    }
    
    if (AVPlayerItem *newPlayerItem = change[NSKeyValueChangeNewKey]) {
        [newPlayerItem addObserver:self forKeyPath:@"duration" options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew context:[EditorPlayerViewVisualProviderReality durationContext]];
    }
}

- (void)statusDidChangeWithObject:(id)object change:(NSDictionary *)change __attribute__((objc_direct)) {
    auto status = static_cast<AVPlayerStatus>(static_cast<NSNumber *>(change[NSKeyValueChangeNewKey]).integerValue);
    
    switch (status) {
        case AVPlayerStatusUnknown:
            dispatch_async(dispatch_get_main_queue(), ^{
                self.playbackButton.configuration = self.loadingButtonConfiguration;
            });
            break;
        case AVPlayerStatusReadyToPlay:
            dispatch_async(dispatch_get_main_queue(), ^{
                self.playbackButton.configuration = self.playButtonConfiguration;
            });
            break;
        case AVPlayerStatusFailed:
            dispatch_async(dispatch_get_main_queue(), ^{
                self.playbackButton.configuration = self.errorButtonConfiguration;
            });
            break;
    }
}

- (void)timeControlStatusDidChangeWithObject:(id)object change:(NSDictionary *)change __attribute__((objc_direct)) {
    auto status = static_cast<AVPlayerTimeControlStatus>(static_cast<NSNumber *>(change[NSKeyValueChangeNewKey]).integerValue);
    
    switch (status) {
        case AVPlayerTimeControlStatusPaused:
            dispatch_async(dispatch_get_main_queue(), ^{
                self.playbackButton.configuration = self.playButtonConfiguration;
            });
            break;
        case AVPlayerTimeControlStatusPlaying:
            dispatch_async(dispatch_get_main_queue(), ^{
                self.playbackButton.configuration = self.pauseButtonConfiguration;
            });
        default:
            break;
    }
}

- (void)durationDidChangeWithObject:(id)object change:(NSDictionary *)change __attribute__((objc_direct)) {
    auto duration = static_cast<NSValue *>(change[NSKeyValueChangeNewKey]).CMTimeValue;
    CMTime convertedTime = CMTimeConvertScale(duration, [EditorPlayerViewVisualProviderReality preferredTimescale], kCMTimeRoundingMethod_RoundAwayFromZero);
    CMTimeValue maximumValue = convertedTime.value;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self.seekSlider.maximumValue = maximumValue;
    });
}

- (UIView *)containerView {
    return self.playerViewController.view;
}

- (_EditorPlayerView *)playerView {
    if (auto playerView = _playerView) return playerView;
    
    _EditorPlayerView *playerView = [[_EditorPlayerView alloc] initWithFrame:self.containerView.bounds];
    playerView.playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
    
    _playerView = [playerView retain];
    return [playerView autorelease];
}

- (UIStackView *)controlView {
    if (auto controlView = _controlView) return controlView;
    
    UIStackView *controlView = [[UIStackView alloc] initWithFrame:self.containerView.bounds];
    controlView.axis = UILayoutConstraintAxisHorizontal;
    controlView.distribution = UIStackViewDistributionFill;
    controlView.alignment = UIStackViewAlignmentFill;
    
    controlView.layer.zPosition = 20.f;
    [controlView _requestSeparatedState:1 withReason:@"SwiftUI.Transform3D"];
    
    _controlView = [controlView retain];
    return [controlView autorelease];
}

- (UIButton *)playbackButton {
    if (auto playbackButton = _playbackButton) return playbackButton;
    
    __weak auto weakSelf = self;
    UIAction *primaryAction = [UIAction actionWithHandler:^(__kindof UIAction * _Nonnull action) {
        auto unwrapped = weakSelf;
        if (unwrapped == nil) return;
        
        if (unwrapped.player.rate > 0.f) {
            [unwrapped.player pause];
        } else {
            [unwrapped.player play];
        }
    }];
    
    UIButton *playbackButton = [UIButton systemButtonWithPrimaryAction:primaryAction];
    
    _playbackButton = [playbackButton retain];
    return playbackButton;
}

- (UISlider *)seekSlider {
    if (auto seekSlider = _seekSlider) return seekSlider;
    
    __weak auto weakSelf = self;
    
    UIAction *touchDragInsideEnterAction = [UIAction actionWithHandler:^(__kindof UIAction * _Nonnull action) {
        [weakSelf.player pause];
    }];
    
    UIAction *valueChangedAction = [UIAction actionWithHandler:^(__kindof UIAction * _Nonnull action) {
        auto seekSlider = static_cast<UISlider *>(action.sender);
        if (!seekSlider.tracking) return;
        CMTime time = CMTimeMake(seekSlider.value, [EditorPlayerViewVisualProviderReality preferredTimescale]);
        [weakSelf.player seekToTime:time toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
    }];
    
    UIAction *touchUpAction = [UIAction actionWithHandler:^(__kindof UIAction * _Nonnull action) {
//        [unretained.player play];
    }];
    
    UISlider *seekSlider = [[UISlider alloc] initWithFrame:self.containerView.bounds];
    seekSlider.minimumValue = 0.f;
    
    [seekSlider addAction:touchDragInsideEnterAction forControlEvents:UIControlEventTouchDragInside];
    [seekSlider addAction:valueChangedAction forControlEvents:UIControlEventValueChanged];
    [seekSlider addAction:touchUpAction forControlEvents:UIControlEventTouchUpInside];
    [seekSlider addAction:touchUpAction forControlEvents:UIControlEventTouchUpOutside];
    
    _seekSlider = [seekSlider retain];
    return [seekSlider autorelease];
}

- (UIButtonConfiguration *)loadingButtonConfiguration {
    UIButtonConfiguration *loadingButtonConfiguration = [UIButtonConfiguration filledButtonConfiguration];
    loadingButtonConfiguration.showsActivityIndicator = YES;
    return loadingButtonConfiguration;
}

- (UIButtonConfiguration *)playButtonConfiguration {
    UIButtonConfiguration *playButtonConfiguration = [UIButtonConfiguration filledButtonConfiguration];
    playButtonConfiguration.image = [UIImage systemImageNamed:@"play.fill"];
    return playButtonConfiguration;
}

- (UIButtonConfiguration *)pauseButtonConfiguration {
    UIButtonConfiguration *pauseButtonConfiguration = [UIButtonConfiguration filledButtonConfiguration];
    pauseButtonConfiguration.image = [UIImage systemImageNamed:@"pause.fill"];
    return pauseButtonConfiguration;
}

- (UIButtonConfiguration *)errorButtonConfiguration {
    UIButtonConfiguration *errorButtonConfiguration = [UIButtonConfiguration filledButtonConfiguration];
    errorButtonConfiguration.image = [UIImage systemImageNamed:@"play.slash.fill"];
    return errorButtonConfiguration;
}

@end

#endif
