//
//  EditorAssetPreviewView.mm
//  SurfVideo
//
//  Created by Jinwoo Kim on 12/17/23.
//

#import "EditorAssetPreviewView.hpp"
#import "EditorAssetPreviewLayerDelegate.hpp"
#import <vector>
#import <numeric>
#import <objc/runtime.h>

__attribute__((objc_direct_members))
@interface EditorAssetPreviewView ()
@property (copy, nonatomic) AVAsset * _Nullable avAsset;
@property (assign, nonatomic) CMTimeRange timeRange;
@property (retain, nonatomic) AVAssetImageGenerator *assetImageGenerator;
@property (retain, readonly, nonatomic) EditorAssetPreviewLayerDelegate *delegate;
@end

@implementation EditorAssetPreviewView

@synthesize delegate = _delegate;

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
    }
    
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    if (self = [super initWithCoder:coder]) {
    }
    
    return self;
}

- (void)dealloc {
    [_avAsset release];
    [_assetImageGenerator cancelAllCGImageGeneration];
    [_assetImageGenerator release];
    [_delegate release];
    [super dealloc];
}

- (void)updateWithAVAsset:(AVAsset *)avAsset timeRange:(CMTimeRange)timeRange {
    self.avAsset = avAsset;
    self.timeRange = timeRange;
    
    [self requestGeneratingImage];
}

- (void)setFrame:(CGRect)frame {
    BOOL shouldRegenerate = !CGRectEqualToRect(self.frame, frame);
    
    [super setFrame:frame];
    
    if (!shouldRegenerate) {
        [self requestGeneratingImage];
    }
}

- (void)requestGeneratingImage __attribute__((objc_direct)) {
    if (auto assetImageGenerator = self.assetImageGenerator) {
        [assetImageGenerator cancelAllCGImageGeneration];
        self.assetImageGenerator = nil;
    }
    
    AVAsset * _Nullable avAsset = self.avAsset;
    if (avAsset == nil) return;
    
    CGSize size = self.bounds.size;
    CGFloat displayScale = self.traitCollection.displayScale;
    if (size.width <= 0.f || size.height <= 0.f || displayScale <= 0.f) return;
    
    CGFloat itemHeight = size.height;
    NSUInteger count = static_cast<NSUInteger>(std::floorf(size.width / itemHeight));
    CGFloat itemWidth = size.width / count;
    
    AVAssetImageGenerator *assetImageGenerator = [[AVAssetImageGenerator alloc] initWithAsset:_avAsset];
    assetImageGenerator.appliesPreferredTrackTransform = YES;
    
    // itemWidth로 안한 것은 의도한 것. 만약에 100x200이 Asset Size이고, Item Size가 50x50라면, Result가 25x50가 나오는 문제가 있다. 50x100으로 나오게 하기 위함.
    assetImageGenerator.maximumSize = CGSizeMake(itemHeight * displayScale, itemHeight * displayScale);
    assetImageGenerator.apertureMode = AVAssetImageGeneratorApertureModeCleanAperture;
    
    // TODO: async
    CMTimeScale timescale = 1000000L;
    CMTime start = CMTimeConvertScale(_timeRange.start, timescale, kCMTimeRoundingMethod_Default);
    CMTime duration = CMTimeConvertScale(_timeRange.duration, timescale, kCMTimeRoundingMethod_Default);
    double durationPerFrame = double(duration.value) / count;
    
    std::vector<NSUInteger> frames(count);
    std::iota(frames.begin(), frames.end(), 0);
    auto times = [[NSMutableArray<NSValue *> alloc] initWithCapacity:count];
    auto sublayers = [[NSMutableArray<CALayer *> alloc] initWithCapacity:count];
    CALayer *layer = self.layer;
    EditorAssetPreviewLayerDelegate *delegate = self.delegate;
    
    auto oldSublayers = reinterpret_cast<NSArray<CALayer *> *>([layer.sublayers copy]);
    [oldSublayers enumerateObjectsUsingBlock:^(__kindof CALayer * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj removeFromSuperlayer];
    }];
    [oldSublayers release];
    
    std::for_each(frames.cbegin(), frames.cend(), [self, itemWidth, itemHeight, start, durationPerFrame, times, sublayers, layer, delegate](NSUInteger frame) {
        [times addObject:[NSValue valueWithCMTime:CMTimeMake(start.value + durationPerFrame * frame, start.timescale)]];
        
        CALayer *sublayer = [[CALayer alloc] initWithLayer:layer];
        sublayer.frame = CGRectMake(itemWidth * frame,
                                    0.f,
                                    itemWidth,
                                    itemHeight);
        sublayer.delegate = delegate;
        sublayer.drawsAsynchronously = YES;
        
        [layer addSublayer:sublayer];
        [sublayers addObject:sublayer];
        [sublayer release];
    });
    
    //
    
    [assetImageGenerator generateCGImagesAsynchronouslyForTimes:times completionHandler:^(CMTime requestedTime, CGImageRef  _Nullable image, CMTime actualTime, AVAssetImageGeneratorResult result, NSError * _Nullable error) {
        if (image) {
            NSInteger index = [times indexOfObject:[NSValue valueWithCMTime:requestedTime]];
            assert(index != NSNotFound);
            
            CALayer *sublayer = sublayers[index];
            id _image = static_cast<id>(image);
            
//            dispatch_async(dispatch_get_main_queue(), ^{
            dispatch_async(dispatch_get_global_queue(0, 0), ^{
                objc_setAssociatedObject(sublayer, EditorAssetPreviewLayerDelegate.imageContextKey, _image, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
                [sublayer setNeedsDisplay];
            });
                
//            });
        }
    }];
    
    [times release];
    [sublayers release];
    
    self.assetImageGenerator = assetImageGenerator;
    [assetImageGenerator release];
}

- (EditorAssetPreviewLayerDelegate *)delegate {
    if (auto delegate = _delegate) return delegate;
    
    EditorAssetPreviewLayerDelegate *delegate = [EditorAssetPreviewLayerDelegate new];
    
    _delegate = [delegate retain];
    return [delegate autorelease];
}

@end
