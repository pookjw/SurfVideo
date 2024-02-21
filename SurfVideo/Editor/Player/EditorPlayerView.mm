//
//  EditorPlayerView.mm
//  SurfVideo
//
//  Created by Jinwoo Kim on 12/4/23.
//

#import "EditorPlayerView.hpp"
#import "UIView+Private.h"
#import <math.h>

// TODO: AVSynchronizedLayer

namespace ns_EditorPlayerView {
    CMTimeScale preferredTimescale = 1000000000L;
    void *statusContext = &statusContext;
    void *timeControlStatusContext = &timeControlStatusContext;
    void *currentItemContext = &currentItemContext;
    void *durationContext = &durationContext;
}

__attribute__((objc_direct_members))
@interface EditorPlayerView ()
@property (retain, readonly, nonatomic) UIStackView *controlView;
@property (retain, readonly, nonatomic) UIButton *playbackButton;
@property (retain, readonly, nonatomic) UISlider *seekSlider;
@property (readonly, nonatomic) UIButtonConfiguration *loadingButtonConfiguration;
@property (readonly, nonatomic) UIButtonConfiguration *playButtonConfiguration;
@property (readonly, nonatomic) UIButtonConfiguration *pauseButtonConfiguration;
@property (readonly, nonatomic) UIButtonConfiguration *errorButtonConfiguration;
@property (retain, nonatomic) id _Nullable timeObserverToken;
@end

@implementation EditorPlayerView

@synthesize controlView = _controlView;
@synthesize playbackButton = _playbackButton;
@synthesize seekSlider = _seekSlider;

+ (Class)layerClass {
    return AVPlayerLayer.class;
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self commonInit_EditorPlayerView];
    }
    
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    if (self = [super initWithCoder:coder]) {
        [self commonInit_EditorPlayerView];
    }
    
    return self;
}

- (void)dealloc {
    if (AVPlayer *player = self.player) {
        [self removeObserverForPlayer:player];
    }
    
    [_controlView release];
    [_playbackButton release];
    [_seekSlider release];
    [_timeObserverToken release];
    [super dealloc];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (context == ns_EditorPlayerView::currentItemContext) {
        [self currentItemDidChangeWithObject:object change:change];
    } else if (context == ns_EditorPlayerView::statusContext) {
        [self statusDidChangeWithObject:object change:change];
    } else if (context == ns_EditorPlayerView::timeControlStatusContext) {
        [self timeControlStatusDidChangeWithObject:object change:change];
    } else if (context == ns_EditorPlayerView::durationContext) {
        [self durationDidChangeWithObject:object change:change];
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (AVPlayer *)player {
    return reinterpret_cast<AVPlayerLayer *>(self.layer).player;
}

- (void)setPlayer:(AVPlayer *)player {
    if (AVPlayer *oldPlayer = self.player) {
        [self removeObserverForPlayer:oldPlayer];
    }
    
    [player addObserver:self forKeyPath:@"currentItem" options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew context:ns_EditorPlayerView::currentItemContext];
    [player addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew context:ns_EditorPlayerView::statusContext];
    [player addObserver:self forKeyPath:@"timeControlStatus" options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew context:ns_EditorPlayerView::timeControlStatusContext];
    
    __weak auto weakSelf = self;
    auto seekSlider = self.seekSlider;
    
    self.timeObserverToken = [player addPeriodicTimeObserverForInterval:CMTimeMake(1, 90) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
        auto _self = weakSelf;
        
        if (auto delegate = _self.delegate) {
            [delegate editorPlayerView:_self didChangeCurrentTime:time];
        }
        
        if (seekSlider.tracking) return;
        seekSlider.value = CMTimeConvertScale(time, ns_EditorPlayerView::preferredTimescale, kCMTimeRoundingMethod_RoundAwayFromZero).value;
    }];
    
    reinterpret_cast<AVPlayerLayer *>(self.layer).player = player;
}

- (void)removeObserverForPlayer:(AVPlayer *)player __attribute__((objc_direct)) {
    [player.currentItem removeObserver:self forKeyPath:@"duration" context:ns_EditorPlayerView::durationContext];
    [player removeObserver:self forKeyPath:@"currentItem" context:ns_EditorPlayerView::currentItemContext];
    [player removeObserver:self forKeyPath:@"status" context:ns_EditorPlayerView::statusContext];
    [player removeObserver:self forKeyPath:@"timeControlStatus" context:ns_EditorPlayerView::timeControlStatusContext];
    
    if (id timeObserverToken = _timeObserverToken) {
        [player removeTimeObserver:timeObserverToken];
    }
}

- (void)currentItemDidChangeWithObject:(id)object change:(NSDictionary *)change __attribute__((objc_direct)) {
    auto currentItem = static_cast<AVPlayerItem *>(change[NSKeyValueChangeNewKey]);
    [currentItem addObserver:self forKeyPath:@"duration" options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew context:ns_EditorPlayerView::durationContext];
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
    CMTime convertedTime = CMTimeConvertScale(duration, ns_EditorPlayerView::preferredTimescale, kCMTimeRoundingMethod_RoundAwayFromZero);
    CMTimeValue maximumValue = convertedTime.value;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self.seekSlider.maximumValue = maximumValue;
    });
}

- (void)commonInit_EditorPlayerView __attribute__((objc_direct)) {
    UIStackView *controlView = self.controlView;
    UIButton *playbackButton = self.playbackButton;
    UISlider *seekSlider = self.seekSlider;
    
    [playbackButton setContentHuggingPriority:UILayoutPriorityDefaultHigh forAxis:UILayoutConstraintAxisHorizontal];
    [seekSlider setContentHuggingPriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
    
    [controlView addArrangedSubview:playbackButton];
    [controlView addArrangedSubview:seekSlider];
    
    controlView.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:controlView];
    [NSLayoutConstraint activateConstraints:@[
        [controlView.leadingAnchor constraintEqualToAnchor:self.layoutMarginsGuide.leadingAnchor constant:20.f],
        [controlView.trailingAnchor constraintEqualToAnchor:self.layoutMarginsGuide.trailingAnchor constant:-20.f],
        [controlView.bottomAnchor constraintEqualToAnchor:self.layoutMarginsGuide.bottomAnchor],
        [controlView.centerXAnchor constraintEqualToAnchor:self.layoutMarginsGuide.centerXAnchor]
    ]];
    
    reinterpret_cast<AVPlayerLayer *>(self.layer).videoGravity = AVLayerVideoGravityResizeAspect;
}

- (UIStackView *)controlView {
    if (auto controlView = _controlView) return controlView;
    
    UIStackView *controlView = [[UIStackView alloc] initWithFrame:self.bounds];
    controlView.axis = UILayoutConstraintAxisHorizontal;
    controlView.distribution = UIStackViewDistributionFill;
    controlView.alignment = UIStackViewAlignmentFill;
    
#if TARGET_OS_VISION
    controlView.layer.zPosition = 30.f;
    [controlView _requestSeparatedState:1 withReason:@"SwiftUI.Transform3D"];
#endif
    
    _controlView = [controlView retain];
    return [controlView autorelease];
}

- (UIButton *)playbackButton {
    if (auto playbackButton = _playbackButton) return playbackButton;
    
    __block auto unretained = self;
    UIAction *primaryAction = [UIAction actionWithHandler:^(__kindof UIAction * _Nonnull action) {
        if (unretained.player.rate > 0.f) {
            [unretained.player pause];
        } else {
            [unretained.player play];
        }
    }];
    
    UIButton *playbackButton = [UIButton systemButtonWithPrimaryAction:primaryAction];
    
    _playbackButton = [playbackButton retain];
    return playbackButton;
}

- (UISlider *)seekSlider {
    if (auto seekSlider = _seekSlider) return seekSlider;
    
    __block auto unretained = self;
    
    UIAction *touchDragInsideEnterAction = [UIAction actionWithHandler:^(__kindof UIAction * _Nonnull action) {
        [unretained.player pause];
    }];
    
    UIAction *valueChangedAction = [UIAction actionWithHandler:^(__kindof UIAction * _Nonnull action) {
        auto seekSlider = static_cast<UISlider *>(action.sender);
        if (!seekSlider.tracking) return;
        CMTime time = CMTimeMake(seekSlider.value, ns_EditorPlayerView::preferredTimescale);
        [unretained.player seekToTime:time toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
    }];
    
    UIAction *touchUpAction = [UIAction actionWithHandler:^(__kindof UIAction * _Nonnull action) {
//        [unretained.player play];
    }];
    
    UISlider *seekSlider = [[UISlider alloc] initWithFrame:self.bounds];
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
