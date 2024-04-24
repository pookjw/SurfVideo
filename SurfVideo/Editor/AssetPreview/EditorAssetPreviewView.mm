//
//  EditorAssetPreviewView.mm
//  SurfVideo
//
//  Created by Jinwoo Kim on 12/17/23.
//

#import "EditorAssetPreviewView.hpp"
#import "_EditorAssetPreviewLayerDelegate.hpp"
#import "SVRunLoop.hpp"
#import "SVAssetThumbnailImageGenerator.hpp"
#import <vector>
#import <numeric>
#import <objc/runtime.h>
#import <CoreFoundation/CoreFoundation.h>
#import <os/lock.h>

__attribute__((objc_direct_members))
@interface EditorAssetPreviewView ()
@property (class, retain, readonly, nonatomic) SVAssetThumbnailImageGenerator *tmp_sharedImageGeneratorInstance;
@property (class, retain, readonly, nonatomic) NSUUID *tmp_UUID;
@property (copy, nonatomic) AVAsset * _Nullable avAsset;
@property (assign, nonatomic) CMTimeRange timeRange;
@property (retain, readonly, nonatomic) _EditorAssetPreviewLayerDelegate *delegate;
@property (assign, nonatomic) CGRect dirtyRect;
@property (retain, readonly, nonatomic) id<UITraitChangeRegistration> displayScaleChangeRegistration;
@property (retain, nonatomic) NSProgress * _Nullable progress;
@end

@implementation EditorAssetPreviewView

@synthesize delegate = _delegate;
@synthesize displayScaleChangeRegistration = _displayScaleChangeRegistration;

+ (SVAssetThumbnailImageGenerator *)tmp_sharedImageGeneratorInstance {
    static dispatch_once_t onceToken;
    static SVAssetThumbnailImageGenerator *instance;
    
    dispatch_once(&onceToken, ^{
        instance = [SVAssetThumbnailImageGenerator new];
    });
    
    return instance;
}

+ (NSUUID *)tmp_UUID {
    static NSUUID *tmp_UUID = [[NSUUID UUID] retain];
    return tmp_UUID;
}

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
    [_delegate release];
    [_displayScaleChangeRegistration release];
    
    if (auto progress = _progress) {
        [progress cancel];
        [progress release];
    }
    
    [super dealloc];
}

- (void)updateWithAVAsset:(AVAsset *)avAsset timeRange:(CMTimeRange)timeRange {
    BOOL shouldRegenerate = (![self.avAsset isEqual:avAsset] || !CMTimeRangeEqual(self.timeRange, timeRange));
    
    self.avAsset = avAsset;
    self.timeRange = timeRange;
    
    if (shouldRegenerate) {
        self.dirtyRect = self.layer.bounds;
        [self requestGeneratingImage];
    }
}

- (void)commonInit_EditorAssetPreviewView __attribute__((objc_direct)) {
    [self displayScaleChangeRegistration];
}

- (void)drawRect:(CGRect)rect {
    [super drawRect:rect];
    
    if (!CGRectEqualToRect(self.dirtyRect, rect)) {
        self.dirtyRect = rect;
        [self requestGeneratingImage];
    }
}

- (void)setFrame:(CGRect)frame {
    [super setFrame:frame];
    
    if (!CGRectEqualToRect(self.dirtyRect, frame)) {
        self.dirtyRect = frame;
        [self requestGeneratingImage];
    }
}

- (void)requestGeneratingImage __attribute__((objc_direct)) {
//    if (auto assetImageGenerator = self.assetImageGenerator) {
//        [assetImageGenerator cancelAllCGImageGeneration];
//        self.assetImageGenerator = nil;
//    }
    
    AVAsset * _Nullable avAsset = self.avAsset;
    if (avAsset == nil) return;
    
    CGSize size = self.bounds.size;
    CGFloat displayScale = self.traitCollection.displayScale;
    if (size.width <= 0.f || size.height <= 0.f || displayScale <= 0.f) return;
    
    CGFloat itemHeight = size.height;
    NSUInteger count = static_cast<NSUInteger>(std::floorf(size.width / itemHeight));
    CGFloat itemWidth = size.width / count;
    
    CGSize maximumSize;
    if (itemWidth < itemHeight) {
        maximumSize = CGSizeMake(itemWidth * displayScale,
                                 0.f);
    } else {
        maximumSize = CGSizeMake(0.f,
                                 itemHeight * displayScale);
    }
    
    // TODO: async
    CMTimeScale timescale = 1000000L;
    CMTime start = CMTimeConvertScale(_timeRange.start, timescale, kCMTimeRoundingMethod_RoundAwayFromZero);
    CMTime duration = CMTimeConvertScale(_timeRange.duration, timescale, kCMTimeRoundingMethod_RoundAwayFromZero);
    double durationPerFrame = double(duration.value) / count;
    
    std::vector<NSUInteger> frames(count);
    std::iota(frames.begin(), frames.end(), 0);
    auto times = [[NSMutableOrderedSet<NSValue *> alloc] initWithCapacity:count];
    auto sublayers = [[NSMutableArray<CALayer *> alloc] initWithCapacity:count];
    CALayer *layer = self.layer;
    _EditorAssetPreviewLayerDelegate *delegate = self.delegate;
    
    [layer.sublayers enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(__kindof CALayer * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj removeFromSuperlayer];
    }];
    
    std::for_each(frames.cbegin(), frames.cend(), [self, itemWidth, itemHeight, displayScale, start, durationPerFrame, times, sublayers, layer, delegate](NSUInteger frame) {
        [times addObject:[NSValue valueWithCMTime:CMTimeMake(start.value + durationPerFrame * frame, start.timescale)]];
        
        CALayer *sublayer = [[CALayer alloc] initWithLayer:layer];
        sublayer.frame = CGRectMake(itemWidth * frame,
                                    0.f,
                                    itemWidth,
                                    itemHeight);
        sublayer.delegate = delegate;
        sublayer.drawsAsynchronously = NO;
        sublayer.contentsScale = displayScale;
        
        [layer addSublayer:sublayer];
        [sublayers addObject:sublayer];
        [sublayer release];
    });
    
    //
    
    [self.progress cancel];
    self.progress = [EditorAssetPreviewView.tmp_sharedImageGeneratorInstance requestThumbnailImagesFromAsset:avAsset
                                                                                assetID:EditorAssetPreviewView.tmp_UUID
                                                                                atTimes:times
                                                                            maximumSize:maximumSize
                                                                         requestHandler:^(CMTime requestedTime, CMTime actualTime, CGImageRef  _Nullable image, NSError * _Nullable error, BOOL isEnd) {
        if (error) {
            NSLog(@"%@", error);
            return;
        }
        
//        if (result != AVAssetImageGeneratorSucceeded) return;
        
        if (image) {
            NSInteger index = [times indexOfObject:[NSValue valueWithCMTime:requestedTime]];
            assert(index != NSNotFound);
            
            CALayer *sublayer = sublayers[index];
            id _image = static_cast<id>(image);
            
            [SVRunLoop.globalRenderRunLoop runBlock:^{
                objc_setAssociatedObject(sublayer, _EditorAssetPreviewLayerDelegate.imageContextKey, _image, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
                [sublayer setNeedsDisplay];
            }];
        }
    }];
    
//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//        [progress cancel];
//    });
    
    [times release];
    [sublayers release];
}

- (_EditorAssetPreviewLayerDelegate *)delegate {
    if (auto delegate = _delegate) return delegate;
    
    _EditorAssetPreviewLayerDelegate *delegate = [_EditorAssetPreviewLayerDelegate new];
    
    _delegate = [delegate retain];
    return [delegate autorelease];
}

- (id<UITraitChangeRegistration>)displayScaleChangeRegistration {
    if (auto displayScaleChangeRegistration = _displayScaleChangeRegistration) return displayScaleChangeRegistration;
    
    id<UITraitChangeRegistration> displayScaleChangeRegistration = [self registerForTraitChanges:@[UITraitDisplayScale.class] withHandler:^(EditorAssetPreviewView * _Nonnull traitEnvironment, UITraitCollection * _Nonnull previousCollection) {
        CGFloat displayScale = traitEnvironment.traitCollection.displayScale;
        
        for (CALayer *sublayer in traitEnvironment.layer.sublayers) {
            sublayer.contentsScale = displayScale;
        }
    }];
    
    _displayScaleChangeRegistration = [displayScaleChangeRegistration retain];
    return displayScaleChangeRegistration;
}

@end
