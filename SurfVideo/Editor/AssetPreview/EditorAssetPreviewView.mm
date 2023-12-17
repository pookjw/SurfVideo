//
//  EditorAssetPreviewView.mm
//  SurfVideo
//
//  Created by Jinwoo Kim on 12/17/23.
//

#import "EditorAssetPreviewView.hpp"
#import <os/lock.h>

__attribute__((objc_direct_members))
@interface EditorAssetPreviewView ()
@property (retain, nonatomic) AVAssetImageGenerator *assetImageGenerator;
@property (assign, nonatomic) CGImageRef image;
@end

@implementation EditorAssetPreviewView

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self commonInit_EditorAssetPreviewView];
    }
    
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    if (self = [super initWithCoder:coder]) {
        [self commonInit_EditorAssetPreviewView];
    }
    
    return self;
}

- (void)dealloc {
    [_assetImageGenerator cancelAllCGImageGeneration];
    [_assetImageGenerator release];
    
    if (_image) {
        CGImageRelease(_image);
    }
    [super dealloc];
}

- (void)setAVAsset:(AVAsset *)avAsset {
    assert([NSThread isMainThread]);
    
    [_avAsset release];
    _avAsset = [avAsset copy];
    
    [self requestGeneratingImage];
}

- (void)setFrame:(CGRect)frame {
    [super setFrame:frame];
    [self requestGeneratingImage];
}


- (void)drawRect:(CGRect)rect {
    CGContextRef context = UIGraphicsGetCurrentContext();
    
//    CGContextSetRGBFillColor(context, 1.f, 1.f, 0.f, 1.f);
//    CGContextFillRect(context, rect)
    
    if (self.image) {
        CGContextDrawImage(context, rect, self.image);
    }
}

- (void)commonInit_EditorAssetPreviewView __attribute__((objc_direct)) {
    
}

- (void)requestGeneratingImage __attribute__((objc_direct)) {
    [_assetImageGenerator cancelAllCGImageGeneration];
    [_assetImageGenerator release];
    _assetImageGenerator = nil;
    
    if (_avAsset == nil) return;
    
    CGFloat scale = self.traitCollection.displayScale;
    CGSize size = self.bounds.size;
    if (size.width <= 0.f || size.height <= 0.f) return;
    
    NSUInteger count = static_cast<NSUInteger>(std::floorf(size.width / size.width));
    if (count == 0) return;
    
    CGSize thumbnailSize = CGSizeMake(size.width / static_cast<CGFloat>(count), size.height);
    
    AVAssetImageGenerator *assetImageGenerator = [[AVAssetImageGenerator alloc] initWithAsset:_avAsset];
//    assetImageGenerator.maximumSize = CGSizeMake(thumbnailSize.width * scale, thumbnailSize.height * scale);
    assetImageGenerator.apertureMode = AVAssetImageGeneratorApertureModeCleanAperture;
    
    // TODO: async
//    CMTimeValue duration = _avAsset.duration.value;
//    CMTimeValue thumbnailDuration = du
    
    auto weakSelf = self;
//    NSArray<NSValue *> *times = @[
//        [NSValue valueWithCMTime:CMTimeMake(0, _avAsset.duration.timescale)]
//    ];
//    [assetImageGenerator generateCGImagesAsynchronouslyForTimes:times completionHandler:^(CMTime requestedTime, CGImageRef  _Nullable image, CMTime actualTime, AVAssetImageGeneratorResult result, NSError * _Nullable error) {
//        if (image) {
//            dispatch_async(dispatch_get_main_queue(), ^{
//                weakSelf.image = image;
//                [weakSelf setNeedsDisplay];
//            });
//        }
//    }];
    
    [assetImageGenerator generateCGImageAsynchronouslyForTime:kCMTimeZero completionHandler:^(CGImageRef  _Nullable image, CMTime actualTime, NSError * _Nullable error) {
        if (image) {
            // TODO: Bridge to Object
            CGImageRetain(image);
            
            dispatch_async(dispatch_get_main_queue(), ^{
                if (weakSelf.image) {
                    CGImageRelease(weakSelf.image);
                }
                
                weakSelf.image = CGImageRetain(image);
                
                [weakSelf setNeedsDisplay];
            });
            
            CGImageRelease(weakSelf.image);
        }
    }];
    
    [_assetImageGenerator release];
    _assetImageGenerator = [assetImageGenerator retain];
    [assetImageGenerator release];
}

@end
