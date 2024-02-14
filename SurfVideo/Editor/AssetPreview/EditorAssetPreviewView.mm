//
//  EditorAssetPreviewView.mm
//  SurfVideo
//
//  Created by Jinwoo Kim on 12/17/23.
//

#import "EditorAssetPreviewView.hpp"
#import "_EditorAssetPreviewLayerDelegate.hpp"
#import <vector>
#import <numeric>
#import <objc/runtime.h>
#import <CoreFoundation/CoreFoundation.h>
#import <os/lock.h>

namespace ns_EditorAssetPreviewView {
    void performCallout(void *info) {
        auto dictionary = static_cast<NSMutableDictionary *>(info);
        os_unfair_lock *lock = reinterpret_cast<os_unfair_lock *>(static_cast<NSValue *>(dictionary[@"lock"]).pointerValue);
        
        os_unfair_lock_lock(lock);
        
        auto blocks = static_cast<NSMutableArray *>(dictionary[@"blocks"]);
        
        [blocks enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            ((void (^)())(obj))();
        }];
        [blocks removeAllObjects];
        
        os_unfair_lock_unlock(lock);
    }
}

__attribute__((objc_direct_members))
@interface EditorAssetPreviewView ()
@property (class, retain, readonly, nonatomic) NSThread *renderThread;
@property (copy, nonatomic) AVAsset * _Nullable avAsset;
@property (assign, nonatomic) CMTimeRange timeRange;
@property (retain, nonatomic) AVAssetImageGenerator *assetImageGenerator;
@property (retain, readonly, nonatomic) _EditorAssetPreviewLayerDelegate *delegate;
@property (assign, nonatomic) CGRect dirtyRect;
@end

@implementation EditorAssetPreviewView

@synthesize delegate = _delegate;

+ (NSThread *)renderThread {
    static dispatch_once_t onceToken;
    static NSThread *renderThread;
    static NSMutableDictionary *dictionary;
    static os_unfair_lock lock;
    
    dispatch_once(&onceToken, ^{
        dictionary = [NSMutableDictionary new];
        lock = OS_UNFAIR_LOCK_INIT;
        
        dictionary[@"lock"] = [NSValue valueWithPointer:&lock];;
        
        renderThread = [[NSThread alloc] initWithBlock:^{
            NSAutoreleasePool *pool = [NSAutoreleasePool new];
            
            CFRunLoopSourceContext context = {
                0,
                dictionary,
                NULL,
                NULL,
                NULL,
                NULL,
                NULL,
                NULL,
                NULL,
                ns_EditorAssetPreviewView::performCallout
            };
            
            CFRunLoopSourceRef source = CFRunLoopSourceCreate(kCFAllocatorDefault,
                                                              0,
                                                              &context);
            
            CFRunLoopAddSource(CFRunLoopGetCurrent(), source, kCFRunLoopDefaultMode);
            
            os_unfair_lock_lock(&lock);
            
            dictionary[@"runLoop"] = static_cast<id>(CFRunLoopGetCurrent());
            dictionary[@"source"] = static_cast<id>(source);
            
            if (NSMutableArray *blocks = dictionary[@"blocks"]) {
                [blocks enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                    ((void (^)())(obj))();
                }];
                [blocks removeAllObjects];
            } else {
                dictionary[@"blocks"] = [NSMutableArray array];
            }
            
            os_unfair_lock_unlock(&lock);
            
            CFRelease(source);
            
            [pool release];
            
            CFRunLoopRun();
        }];
        
        renderThread.threadDictionary[@"dictionary"] = dictionary;
        renderThread.name = @"RenderThread";
        
        [renderThread start];
    });
    
    return renderThread;
}

+ (void)runRenderBlock:(void (^)())block __attribute__((objc_direct)) {
    NSThread *renderThread = self.renderThread;
    NSMutableDictionary *dictionary = renderThread.threadDictionary[@"dictionary"];
    os_unfair_lock *lock = reinterpret_cast<os_unfair_lock *>(static_cast<NSValue *>(dictionary[@"lock"]).pointerValue);
    
    os_unfair_lock_lock(lock);
    
    auto runLoop = reinterpret_cast<CFRunLoopRef _Nullable>(dictionary[@"runLoop"]);
    auto source = reinterpret_cast<CFRunLoopSourceRef _Nullable>(dictionary[@"source"]);
    
    NSMutableArray *blocks;
    if (NSMutableArray *_blocks = dictionary[@"blocks"]) {
        blocks = _blocks;
    } else {
        blocks = [NSMutableArray array];
        dictionary[@"blocks"] = blocks;
    }
    
    id copiedBlock = [block copy];
    [blocks addObject:copiedBlock];
    [copiedBlock release];
    
    os_unfair_lock_unlock(lock);
    
    if (source) {
        CFRunLoopSourceSignal(source);
    }
    
    if (runLoop) {
        CFRunLoopWakeUp(runLoop);
    }
}

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
    BOOL shouldRegenerate = (![self.avAsset isEqual:avAsset] || !CMTimeRangeEqual(self.timeRange, timeRange));
    
    self.avAsset = avAsset;
    self.timeRange = timeRange;
    
    if (shouldRegenerate) {
        [self requestGeneratingImage];
    }
}

- (void)drawRect:(CGRect)rect {
    [super drawRect:rect];
    
    if (!CGRectEqualToRect(self.dirtyRect, rect)) {
        [self requestGeneratingImage];
        self.dirtyRect = rect;
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
    assetImageGenerator.requestedTimeToleranceBefore = kCMTimeZero;
    assetImageGenerator.requestedTimeToleranceAfter = kCMTimeZero;
    
    // TODO: async
    CMTimeScale timescale = 1000000L;
    CMTime start = CMTimeConvertScale(_timeRange.start, timescale, kCMTimeRoundingMethod_RoundAwayFromZero);
    CMTime duration = CMTimeConvertScale(_timeRange.duration, timescale, kCMTimeRoundingMethod_RoundAwayFromZero);
    double durationPerFrame = double(duration.value) / count;
    
    std::vector<NSUInteger> frames(count);
    std::iota(frames.begin(), frames.end(), 0);
    auto times = [[NSMutableArray<NSValue *> alloc] initWithCapacity:count];
    auto sublayers = [[NSMutableArray<CALayer *> alloc] initWithCapacity:count];
    CALayer *layer = self.layer;
    _EditorAssetPreviewLayerDelegate *delegate = self.delegate;
    
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
        sublayer.drawsAsynchronously = NO;
        
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
            
            [EditorAssetPreviewView runRenderBlock:^{
                objc_setAssociatedObject(sublayer, _EditorAssetPreviewLayerDelegate.imageContextKey, _image, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
                [sublayer setNeedsDisplay];
            }];
        }
    }];
    
    [times release];
    [sublayers release];
    
    self.assetImageGenerator = assetImageGenerator;
    [assetImageGenerator release];
}

- (_EditorAssetPreviewLayerDelegate *)delegate {
    if (auto delegate = _delegate) return delegate;
    
    _EditorAssetPreviewLayerDelegate *delegate = [_EditorAssetPreviewLayerDelegate new];
    
    _delegate = [delegate retain];
    return [delegate autorelease];
}

@end
