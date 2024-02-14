//
//  EditorTrackMainVideoTrackContentView.m
//  SurfVideo
//
//  Created by Jinwoo Kim on 12/17/23.
//

#import "EditorTrackMainVideoTrackContentView.hpp"
#import "EditorAssetPreviewView.hpp"

__attribute__((objc_direct_members))
@interface EditorTrackMainVideoTrackContentView ()
@property (copy, nonatomic) EditorTrackMainVideoTrackContentConfiguration *contentConfiguration;
@property (retain, readonly, nonatomic) EditorAssetPreviewView *assetPreviewView;
@end

@implementation EditorTrackMainVideoTrackContentView
@synthesize assetPreviewView = _assetPreviewView;

- (instancetype)initWithContentConfiguration:(EditorTrackMainVideoTrackContentConfiguration *)contentConfiguration {
    if (self = [super initWithFrame:CGRectNull]) {
        _contentConfiguration = [contentConfiguration copy];
        [self setupAssetPreviewView];
    }
    
    return self;
}

- (void)dealloc {
    [_contentConfiguration release];
    [_assetPreviewView release];
    [super dealloc];
}

- (id<UIContentConfiguration>)configuration {
    return self.contentConfiguration;
}

- (void)setConfiguration:(id<UIContentConfiguration>)configuration {
    self.contentConfiguration = configuration;
}

- (void)setContentConfiguration:(EditorTrackMainVideoTrackContentConfiguration *)contentConfiguration {
    [_contentConfiguration release];
    _contentConfiguration = [contentConfiguration copy];
    
    auto userInfo = contentConfiguration.itemModel.userInfo;
    auto *compositionTrack = static_cast<AVCompositionTrack *>(contentConfiguration.sectionModel.userInfo[EditorTrackSectionModelCompositionTrackKey]);
    auto avAsset = static_cast<AVAsset *>(compositionTrack.asset);
    auto trackSegment = static_cast<AVCompositionTrackSegment *>(userInfo[EditorTrackItemModelCompositionTrackSegmentKey]);
    
    [self.assetPreviewView updateWithAVAsset:avAsset timeRange:trackSegment.timeMapping.target];
}

- (void)setupAssetPreviewView __attribute__((objc_direct)) {
    EditorAssetPreviewView *assetPreviewView = self.assetPreviewView;
    assetPreviewView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self addSubview:assetPreviewView];
}

- (EditorAssetPreviewView *)assetPreviewView {
    if (auto assetPreviewView = _assetPreviewView) return assetPreviewView;
    
    EditorAssetPreviewView *assetPreviewView = [[EditorAssetPreviewView alloc] initWithFrame:self.bounds];
    
    _assetPreviewView = [assetPreviewView retain];
    return [assetPreviewView autorelease];
}

@end
