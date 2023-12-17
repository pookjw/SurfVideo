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
    
    _assetPreviewView.avAsset = static_cast<AVComposition *>(contentConfiguration.itemModel.userInfo[EditorTrackItemModelCompositionKey]);
}

- (void)setupAssetPreviewView __attribute__((objc_direct)) {
    EditorAssetPreviewView *assetPreviewView = self.assetPreviewView;
    assetPreviewView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self addSubview:assetPreviewView];
}

- (EditorAssetPreviewView *)assetPreviewView {
    if (_assetPreviewView) return _assetPreviewView;
    
    EditorAssetPreviewView *assetPreviewView = [[EditorAssetPreviewView alloc] initWithFrame:self.bounds];
    
    [_assetPreviewView release];
    _assetPreviewView = [assetPreviewView retain];
    
    return [assetPreviewView autorelease];
}

@end
