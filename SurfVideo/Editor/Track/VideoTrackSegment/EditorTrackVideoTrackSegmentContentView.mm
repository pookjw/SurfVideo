//
//  EditorTrackVideoTrackSegmentContentView.m
//  SurfVideo
//
//  Created by Jinwoo Kim on 12/17/23.
//

#import "EditorTrackVideoTrackSegmentContentView.hpp"
#import "EditorAssetPreviewView.hpp"

__attribute__((objc_direct_members))
@interface EditorTrackVideoTrackSegmentContentView ()
@property (copy, nonatomic) EditorTrackVideoTrackSegmentContentConfiguration *contentConfiguration;
@property (retain, readonly, nonatomic) EditorAssetPreviewView *assetPreviewView;
@end

@implementation EditorTrackVideoTrackSegmentContentView
@synthesize assetPreviewView = _assetPreviewView;

- (instancetype)initWithContentConfiguration:(EditorTrackVideoTrackSegmentContentConfiguration *)contentConfiguration {
    if (self = [super initWithFrame:CGRectNull]) {
        [self setupAssetPreviewView];
        self.contentConfiguration = contentConfiguration;
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

- (BOOL)supportsConfiguration:(id<UIContentConfiguration>)configuration {
    return [configuration isKindOfClass:EditorTrackVideoTrackSegmentContentConfiguration.class];
}

- (void)setContentConfiguration:(EditorTrackVideoTrackSegmentContentConfiguration *)contentConfiguration {
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
