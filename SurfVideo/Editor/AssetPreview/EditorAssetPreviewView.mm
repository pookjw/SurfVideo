//
//  EditorAssetPreviewView.mm
//  SurfVideo
//
//  Created by Jinwoo Kim on 12/17/23.
//

#import "EditorAssetPreviewView.hpp"
#import <vector>
#import <numeric>

__attribute__((objc_direct_members))
@interface EditorAssetPreviewView ()
@property (copy, nonatomic) AVAsset * _Nullable avAsset;
@property (assign, nonatomic) CMTimeRange timeRange;
@property (retain, nonatomic) AVAssetImageGenerator *assetImageGenerator;
@property (copy, nonatomic) NSDictionary<NSValue *, id> *images;
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
    [_avAsset release];
    [_assetImageGenerator cancelAllCGImageGeneration];
    [_assetImageGenerator release];
    [_images release];
    [super dealloc];
}

- (void)updateWithAVAsset:(AVAsset *)avAsset timeRange:(CMTimeRange)timeRange {
    self.avAsset = avAsset;
    self.timeRange = timeRange;
    
    [self requestGeneratingImage];
}

- (void)setFrame:(CGRect)frame {
    [super setFrame:frame];
    [self requestGeneratingImage];
}


// TODO: CALayer로 부분적으로만 그리기
- (void)drawRect:(CGRect)rect {
    CGContextRef context = UIGraphicsGetCurrentContext();
    
//    CGContextSetRGBFillColor(context, 1.f, 1.f, 0.f, 1.f);
//    CGContextFillRect(context, rect)
    
    if (_images) {
        NSArray<NSValue *> *sortedKeys = [_images.allKeys sortedArrayUsingComparator:^NSComparisonResult(NSValue * _Nonnull obj1, NSValue * _Nonnull obj2) {
            CMTime obj1_time = obj1.CMTimeValue;
            CMTime obj2_time = obj2.CMTimeValue;
            
            return [[NSNumber numberWithInteger:obj1_time.value] compare:[NSNumber numberWithInteger:obj2_time.value]];
        }];
        
        CGFloat x = 0.f;
        for (NSValue *key in sortedKeys) {
            id image = _images[key];
            CGImageRef imageRef = static_cast<CGImageRef>(image);
//            CGFloat width = CGImageGetWidth(imageRef);
            CGFloat height = CGImageGetHeight(imageRef);
            
            CGRect drawRect = CGRectMake(x, rect.origin.y, height, height);
            CGContextDrawImage(context, drawRect, imageRef);
            x += height;
        }
    }
}

- (void)commonInit_EditorAssetPreviewView __attribute__((objc_direct)) {
    
}

- (void)requestGeneratingImage __attribute__((objc_direct)) {
    [_assetImageGenerator cancelAllCGImageGeneration];
    [_assetImageGenerator release];
    _assetImageGenerator = nil;
    
    if (_avAsset == nil) return;
    
    CGSize size = self.bounds.size;
    if (size.width <= 0.f || size.height <= 0.f) return;
    
    NSUInteger count = static_cast<NSUInteger>(std::floorf(size.width / size.height));
    if (count == 0) return;
    
    CGSize thumbnailSize = CGSizeMake(size.width / static_cast<CGFloat>(count), size.height);
    
    AVAssetImageGenerator *assetImageGenerator = [[AVAssetImageGenerator alloc] initWithAsset:_avAsset];
    assetImageGenerator.maximumSize = thumbnailSize;
    assetImageGenerator.apertureMode = AVAssetImageGeneratorApertureModeCleanAperture;
    
    // TODO: async
    CMTime avAssetDuration = _avAsset.duration;
    CMTime start = CMTimeConvertScale(_timeRange.start, avAssetDuration.timescale, kCMTimeRoundingMethod_Default);
    CMTime duration = CMTimeConvertScale(_timeRange.duration, avAssetDuration.timescale, kCMTimeRoundingMethod_Default);
    CMTimeValue durationForFrame = duration.value / count;
    
    std::vector<NSUInteger> frames(count);
    std::iota(frames.begin(), frames.end(), 0);
    auto times = [NSMutableArray<NSValue *> new];
    
    std::for_each(frames.cbegin(), frames.cend(), [start, durationForFrame, times](NSUInteger frame) {
        [times addObject:[NSValue valueWithCMTime:CMTimeMake(start.value + durationForFrame * frame, start.timescale)]];
    });
    
    self.images = @{};
    auto weakSelf = self;
    [assetImageGenerator generateCGImagesAsynchronouslyForTimes:times completionHandler:^(CMTime requestedTime, CGImageRef  _Nullable image, CMTime actualTime, AVAssetImageGeneratorResult result, NSError * _Nullable error) {
        if (image) {
            id _image = static_cast<id>(image);
            
            dispatch_async(dispatch_get_main_queue(), ^{
                auto loaded = weakSelf;
                auto mutableImages = static_cast<NSMutableDictionary<NSValue *, id> *>([loaded.images mutableCopy]);
                mutableImages[[NSValue valueWithCMTime:actualTime]] = _image;
                loaded.images = mutableImages;
                [mutableImages release];
                [loaded setNeedsDisplay];
            });
        }
    }];
    
    [times release];
    
    [_assetImageGenerator release];
    _assetImageGenerator = [assetImageGenerator retain];
    [assetImageGenerator release];
}

@end
