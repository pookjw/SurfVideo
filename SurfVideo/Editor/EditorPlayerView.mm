//
//  EditorPlayerView.mm
//  SurfVideo
//
//  Created by Jinwoo Kim on 12/4/23.
//

#import "EditorPlayerView.hpp"
#import <objc/message.h>
#import <objc/runtime.h>

// TODO: AVSynchronizedLayer

namespace _EditorPlayerView {
    void *statusContext = &statusContext;
    void *rateContext = &rateContext;
}

__attribute__((objc_direct_members))
@interface EditorPlayerView ()
@property (retain, readonly, nonatomic) UIStackView *controlView;
@property (retain, readonly, nonatomic) UIButton *playbackButton;
@property (readonly, nonatomic) UIButtonConfiguration *loadingButtonConfiguration;
@property (readonly, nonatomic) UIButtonConfiguration *playButtonConfiguration;
@property (readonly, nonatomic) UIButtonConfiguration *pauseButtonConfiguration;
@property (readonly, nonatomic) UIButtonConfiguration *errorButtonConfiguration;
@end

@implementation EditorPlayerView
@synthesize controlView = _controlView;
@synthesize playbackButton = _playbackButton;

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
    [super dealloc];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (context == _EditorPlayerView::statusContext) {
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
    } else if (context == _EditorPlayerView::rateContext) {
        float rate = static_cast<NSNumber *>(change[NSKeyValueChangeNewKey]).floatValue;
        
        if (rate > 0.f) {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.playbackButton.configuration = self.pauseButtonConfiguration;
            });
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.playbackButton.configuration = self.playButtonConfiguration;
            });
        }
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
    
    [player addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew context:_EditorPlayerView::statusContext];
    [player addObserver:self forKeyPath:@"rate" options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew context:_EditorPlayerView::rateContext];
    
    reinterpret_cast<AVPlayerLayer *>(self.layer).player = player;
}

- (void)removeObserverForPlayer:(AVPlayer *)player __attribute__((objc_direct)) {
    [player removeObserver:self forKeyPath:@"status" context:_EditorPlayerView::statusContext];
    [player removeObserver:self forKeyPath:@"rate" context:_EditorPlayerView::rateContext];
}

- (void)commonInit_EditorPlayerView __attribute__((objc_direct)) {
    UIStackView *controlView = self.controlView;
    UIButton *playbackButton = self.playbackButton;
    
    [controlView addArrangedSubview:playbackButton];
    controlView.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:controlView];
    [NSLayoutConstraint activateConstraints:@[
        [controlView.leadingAnchor constraintGreaterThanOrEqualToAnchor:self.layoutMarginsGuide.leadingAnchor],
        [controlView.trailingAnchor constraintLessThanOrEqualToAnchor:self.layoutMarginsGuide.trailingAnchor],
        [controlView.bottomAnchor constraintEqualToAnchor:self.layoutMarginsGuide.bottomAnchor],
        [controlView.centerXAnchor constraintEqualToAnchor:self.layoutMarginsGuide.centerXAnchor]
    ]];
}

- (UIStackView *)controlView {
    if (_controlView) return _controlView;
    
    UIStackView *controlView = [[UIStackView alloc] initWithFrame:self.bounds];
    controlView.axis = UILayoutConstraintAxisHorizontal;
    controlView.distribution = UIStackViewDistributionFillProportionally;
    controlView.alignment = UIStackViewAlignmentFill;
    reinterpret_cast<void (*)(id, SEL, long)>(objc_msgSend)(controlView, NSSelectorFromString(@"sws_enablePlatter:"), UIBlurEffectStyleSystemMaterial);
    
    controlView.layer.zPosition = 100.f;
    reinterpret_cast<void (*)(id, SEL, NSUInteger, id)>(objc_msgSend)(controlView, NSSelectorFromString(@"_requestSeparatedState:withReason:"), 1, @"SwiftUI.Transform3D");
    
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
