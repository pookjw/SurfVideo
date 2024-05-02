//
//  EditorTrackAudioTrackSegmentPreviewViewController.mm
//  SurfVideo
//
//  Created by Jinwoo Kim on 5/3/24.
//

#import "EditorTrackAudioTrackSegmentPreviewViewController.hpp"

@interface EditorTrackAudioTrackSegmentPreviewViewController ()

@end

@implementation EditorTrackAudioTrackSegmentPreviewViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        [self commonInit_EditorTrackAudioTrackSegmentPreviewViewController];
    }
    
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    if (self = [super initWithCoder:coder]) {
        [self commonInit_EditorTrackAudioTrackSegmentPreviewViewController];
    }
    
    return self;
}

- (void)commonInit_EditorTrackAudioTrackSegmentPreviewViewController __attribute__((objc_direct)) {
    self.preferredContentSize = CGSizeMake(200., 200.);
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.systemPinkColor;
}

@end
