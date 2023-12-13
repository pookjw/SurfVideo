//
//  EditorPlayerView.mm
//  SurfVideo
//
//  Created by Jinwoo Kim on 12/4/23.
//

#import "EditorPlayerView.hpp"
#import <objc/message.h>
#import <objc/runtime.h>
#import <TargetConditionals.h>
#import <math.h>

// TODO: AVSynchronizedLayer

namespace _EditorPlayerView {
    CMTimeScale preferredTimescale = 1000000000;
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
    if (AVPlayer *oldPlayer = self.player) {
        [self removeObserverForPlayer:oldPlayer];
    }
    [_controlView release];
    [_playbackButton release];
    [_seekSlider release];
    [_timeObserverToken release];
    [super dealloc];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (context == _EditorPlayerView::currentItemContext) {
        auto currentItem = static_cast<AVPlayerItem *>(change[NSKeyValueChangeNewKey]);
        [currentItem addObserver:self forKeyPath:@"duration" options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew context:_EditorPlayerView::durationContext];
    } else if (context == _EditorPlayerView::statusContext) {
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
    } else if (context == _EditorPlayerView::timeControlStatusContext) {
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
    } else if (context == _EditorPlayerView::durationContext) {
        auto duration = static_cast<NSValue *>(change[NSKeyValueChangeNewKey]).CMTimeValue;
        CMTime convertedTime = CMTimeConvertScale(duration, _EditorPlayerView::preferredTimescale, kCMTimeRoundingMethod_Default);
        CMTimeValue maximumValue = convertedTime.value;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            self.seekSlider.maximumValue = maximumValue;
        });
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
    
    [player addObserver:self forKeyPath:@"currentItem" options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew context:_EditorPlayerView::currentItemContext];
    [player addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew context:_EditorPlayerView::statusContext];
    [player addObserver:self forKeyPath:@"timeControlStatus" options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew context:_EditorPlayerView::timeControlStatusContext];
    auto seekSlider = self.seekSlider;
    self.timeObserverToken = [player addPeriodicTimeObserverForInterval:CMTimeMake(1, 90) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
        if (seekSlider.tracking) return;
        seekSlider.value = CMTimeConvertScale(time, _EditorPlayerView::preferredTimescale, kCMTimeRoundingMethod_Default).value;
    }];
    
    reinterpret_cast<AVPlayerLayer *>(self.layer).player = player;
}

- (void)removeObserverForPlayer:(AVPlayer *)player __attribute__((objc_direct)) {
    [player.currentItem removeObserver:self forKeyPath:@"duration" context:_EditorPlayerView::durationContext];
    [player removeObserver:self forKeyPath:@"currentItem" context:_EditorPlayerView::currentItemContext];
    [player removeObserver:self forKeyPath:@"status" context:_EditorPlayerView::statusContext];
    [player removeObserver:self forKeyPath:@"timeControlStatus" context:_EditorPlayerView::timeControlStatusContext];
    
    if (_timeObserverToken) {
        [player removeTimeObserver:_timeObserverToken];
    }
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
        [controlView.leadingAnchor constraintEqualToAnchor:self.layoutMarginsGuide.leadingAnchor],
        [controlView.trailingAnchor constraintEqualToAnchor:self.layoutMarginsGuide.trailingAnchor],
        [controlView.bottomAnchor constraintEqualToAnchor:self.layoutMarginsGuide.bottomAnchor],
        [controlView.centerXAnchor constraintEqualToAnchor:self.layoutMarginsGuide.centerXAnchor]
    ]];
    
    reinterpret_cast<AVPlayerLayer *>(self.layer).videoGravity = AVLayerVideoGravityResizeAspect;
}

- (UIStackView *)controlView {
    if (_controlView) return _controlView;
    
    UIStackView *controlView = [[UIStackView alloc] initWithFrame:self.bounds];
    controlView.axis = UILayoutConstraintAxisHorizontal;
    controlView.distribution = UIStackViewDistributionFill;
    controlView.alignment = UIStackViewAlignmentFill;
    
#if TARGET_OS_VISION
    reinterpret_cast<void (*)(id, SEL, long)>(objc_msgSend)(controlView, NSSelectorFromString(@"sws_enablePlatter:"), UIBlurEffectStyleSystemMaterial);
    
//    controlView.layer.zPosition = 100.f;
//    reinterpret_cast<void (*)(id, SEL, NSUInteger, id)>(objc_msgSend)(controlView, NSSelectorFromString(@"_requestSeparatedState:withReason:"), 1, @"SwiftUI.Transform3D");
#endif
    
    [_controlView release];
    _controlView = [controlView retain];
    
    return [controlView autorelease];
}

- (UIButton *)playbackButton {
    if (_playbackButton) return _playbackButton;
    
    __block auto unretained = self;
    UIAction *primaryAction = [UIAction actionWithHandler:^(__kindof UIAction * _Nonnull action) {
        if (unretained.player.rate > 0.f) {
            [unretained.player pause];
        } else {
            [unretained.player play];
        }
    }];
    
    UIButton *playbackButton = [UIButton systemButtonWithPrimaryAction:primaryAction];
    
    [_playbackButton release];
    _playbackButton = [playbackButton retain];
    
    return playbackButton;
}

- (UISlider *)seekSlider {
    if (_seekSlider) return _seekSlider;
    
    __block auto unretained = self;
    
    UIAction *touchDragInsideEnterAction = [UIAction actionWithHandler:^(__kindof UIAction * _Nonnull action) {
        [unretained.player pause];
    }];
    
    UIAction *valueChangedAction = [UIAction actionWithHandler:^(__kindof UIAction * _Nonnull action) {
        auto seekSlider = static_cast<UISlider *>(action.sender);
        if (!seekSlider.tracking) return;
        CMTime time = CMTimeMake(seekSlider.value, _EditorPlayerView::preferredTimescale);
        [unretained.player seekToTime:time toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
    }];
    
    UIAction *touchUpAction = [UIAction actionWithHandler:^(__kindof UIAction * _Nonnull action) {
        [unretained.player play];
    }];
    
    UISlider *seekSlider = [[UISlider alloc] initWithFrame:self.bounds];
    seekSlider.minimumValue = 0.f;
    
    [seekSlider addAction:touchDragInsideEnterAction forControlEvents:UIControlEventTouchDragInside];
    [seekSlider addAction:valueChangedAction forControlEvents:UIControlEventValueChanged];
    [seekSlider addAction:touchUpAction forControlEvents:UIControlEventTouchUpInside];
    [seekSlider addAction:touchUpAction forControlEvents:UIControlEventTouchUpOutside];
    
    [_seekSlider release];
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
