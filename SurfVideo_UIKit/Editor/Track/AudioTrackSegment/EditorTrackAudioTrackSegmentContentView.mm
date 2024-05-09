//
//  EditorTrackAudioTrackSegmentContentView.mm
//  SurfVideo
//
//  Created by Jinwoo Kim on 3/10/24.
//

#import "EditorTrackAudioTrackSegmentContentView.hpp"
#import <SurfVideoCore/AudioWaveformView.hpp>
#import "UIView+Private.h"
#import <TargetConditionals.h>

__attribute__((objc_direct_members))
@interface EditorTrackAudioTrackSegmentContentView ()
@property (copy, nonatomic) EditorTrackAudioTrackSegmentContentConfiguration *contentConfiguration;
@property (retain, readonly, nonatomic) AudioWaveformView *audioWaveformView;
@property (retain, readonly, nonatomic) UILabel *titleLabel;
@end

@implementation EditorTrackAudioTrackSegmentContentView

@synthesize audioWaveformView = _audioWaveformView;
@synthesize titleLabel = _titleLabel;

- (instancetype)initWithContentConfiguration:(EditorTrackAudioTrackSegmentContentConfiguration *)contentConfiguration {
    if (self = [super initWithFrame:CGRectNull]) {
        [self setupAudioWaveformView];
        [self setupTitleLabel];
        self.backgroundColor = [UIColor.systemPinkColor colorWithAlphaComponent:0.5f];
        self.contentConfiguration = contentConfiguration;
    }
    
    return self;
}

- (void)dealloc {
    [_contentConfiguration release];
    [_audioWaveformView release];
    [_titleLabel release];
    [super dealloc];
}

- (id<UIContentConfiguration>)configuration {
    return self.contentConfiguration;
}

- (void)setConfiguration:(id<UIContentConfiguration>)configuration {
    self.contentConfiguration = configuration;
}

- (BOOL)supportsConfiguration:(id<UIContentConfiguration>)configuration {
    return [configuration isKindOfClass:EditorTrackAudioTrackSegmentContentConfiguration.class];
}

- (void)setContentConfiguration:(EditorTrackAudioTrackSegmentContentConfiguration *)contentConfiguration {
    [_contentConfiguration release];
    _contentConfiguration = [contentConfiguration copy];
    
    EditorTrackItemModel *itemModel = contentConfiguration.itemModel;
    auto trackSegment = itemModel.compositionTrackSegment;
    self.audioWaveformView.avAsset = [AVAsset assetWithURL:trackSegment.sourceURL];
    self.titleLabel.text = itemModel.compositionTrackSegmentName;
}

- (AudioWaveformView *)audioWaveformView {
    if (auto audioWaveformView = _audioWaveformView) return audioWaveformView;
    
    AudioWaveformView *audioWaveformView = [[AudioWaveformView alloc] initWithFrame:self.bounds];
    audioWaveformView.waveformColor = [UIColor.whiteColor colorWithAlphaComponent:0.5f];
    
    _audioWaveformView = [audioWaveformView retain];
    return [audioWaveformView autorelease];
}

- (UILabel *)titleLabel {
    if (auto titleLabel = _titleLabel) return titleLabel;
    
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:self.bounds];
#if TARGET_OS_VISION
    [titleLabel _requestSeparatedState:1 withReason:@"SwiftUI.Transform3D"];
    titleLabel.layer.zPosition = 20.f;
#endif
    
    _titleLabel = [titleLabel retain];
    return [titleLabel autorelease];
}

- (void)setupAudioWaveformView __attribute__((objc_direct)) {
    AudioWaveformView *audioWaveformView = self.audioWaveformView;
    audioWaveformView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self addSubview:audioWaveformView];
}

- (void)setupTitleLabel __attribute__((objc_direct)) {
    UILabel *titleLabel = self.titleLabel;
    titleLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self addSubview:titleLabel];
}

@end
