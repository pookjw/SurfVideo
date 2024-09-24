//
//  EditorTrackAudioTrackSegmentPreviewViewController.mm
//  SurfVideo
//
//  Created by Jinwoo Kim on 5/3/24.
//

#import "EditorTrackAudioTrackSegmentPreviewViewController.hpp"

__attribute__((objc_direct_members))
@interface EditorTrackAudioTrackSegmentPreviewViewController ()
@property (retain, readonly, nonatomic) AVURLAsset *avAsset;
@property (retain, readonly, nonatomic) UIImageView *imageView;
@end

@implementation EditorTrackAudioTrackSegmentPreviewViewController
@synthesize imageView = _imageView;

- (instancetype)initWithAVCompositionTrackSegment:(AVCompositionTrackSegment *)compositionTrackSegment {
    NSURL *sourceURL = compositionTrackSegment.sourceURL;
    
    if (sourceURL == nil) return nil;
    
    if (self = [super initWithNibName:nil bundle:nil]) {
        _avAsset = [[AVURLAsset alloc] initWithURL:sourceURL options:nil];
    }
    
    return self;
}

- (void)dealloc {
    [_avAsset release];
    [_imageView release];
    [super dealloc];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIImageView *imageView = self.imageView;
    imageView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:imageView];
    [NSLayoutConstraint activateConstraints:@[
        [imageView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [imageView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [imageView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [imageView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor]
    ]];
    
    [self loadArtworkImage];
}

- (void)loadArtworkImage __attribute__((objc_direct)) {
    UIImageView *imageView = self.imageView;
    
    [_avAsset loadMetadataForFormat:AVMetadataFormatID3Metadata completionHandler:^(NSArray<AVMetadataItem *> * _Nullable metadataItems, NSError * _Nullable error) {
        UIImage *image = nil;
        
        if (error != nil) {
            NSLog(@"%@", error);
            image = [UIImage systemImageNamed:@"exclamationmark.square.fill"];
        } else {
            for (AVMetadataItem *metadataItem in metadataItems) {
                if (![metadataItem.commonKey isEqualToString:AVMetadataCommonKeyArtwork]) {
                    continue;
                }
                
                NSData *value = (NSData *)metadataItem.value;
                
                if ([value isKindOfClass:[NSData class]]) {
                    image = [UIImage imageWithData:value];
                    break;
                }
            }
            
            if (image == nil) {
                image = [UIImage systemImageNamed:@"music.note"];
            }
        }
        
        if (image.symbolImage) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (imageView.superview == nil) return;;
                imageView.image = image;
            });
        } else {
            [image prepareForDisplayWithCompletionHandler:^(UIImage * _Nullable displayImage) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (imageView.superview == nil) return;;
                    imageView.image = displayImage;
                });
            }];
        }
    }];
}

- (UIImageView *)imageView {
    if (auto imageView = _imageView) return imageView;
    
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:self.view.bounds];
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    imageView.backgroundColor = UIColor.clearColor;
    
    _imageView = [imageView retain];
    return [imageView autorelease];
}

@end
