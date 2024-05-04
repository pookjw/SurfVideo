//
//  EditorTrackAudioTrackSegmentPreviewViewController.mm
//  SurfVideo
//
//  Created by Jinwoo Kim on 5/3/24.
//

#import "EditorTrackAudioTrackSegmentPreviewViewController.hpp"

__attribute__((objc_direct_members))
@interface EditorTrackAudioTrackSegmentPreviewViewController ()
@property (retain, nonatomic) AVURLAsset *avAsset;
@end

@implementation EditorTrackAudioTrackSegmentPreviewViewController

- (instancetype)initWithAVCompositionTrackSegment:(AVCompositionTrackSegment *)compositionTrackSegment {
    NSURL *sourceURL = compositionTrackSegment.sourceURL;
    
    if (sourceURL == nil) return nil;
    
    if (self = [super initWithNibName:nil bundle:nil]) {
        _avAsset = [[AVURLAsset assetWithURL:sourceURL] retain];
    }
    
    return self;
}

- (void)dealloc {
    [_avAsset release];
    [super dealloc];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.systemPinkColor;
}

@end
