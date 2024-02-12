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
@interface _EditorAssetPreviewImage : NSObject
@property (assign, nonatomic) CGRect rect;
@property (retain, nonatomic) id imageRef;
@end

@implementation _EditorAssetPreviewImage

- (void)dealloc {
    CGImageRelease(reinterpret_cast<CGImageRef>(_imageRef));
    [super dealloc];
}

@end

__attribute__((objc_direct_members))
@interface EditorAssetPreviewView ()
@property (copy, nonatomic) AVAsset * _Nullable avAsset;
@property (assign, nonatomic) CMTimeRange timeRange;
@property (retain, nonatomic) AVAssetImageGenerator *assetImageGenerator;
@property (copy, atomic) NSArray<_EditorAssetPreviewImage *> *previewImages;
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
//- (void)drawRect:(CGRect)rect {
//    CGContextRef context = UIGraphicsGetCurrentContext();
//    
////    CGContextSetRGBFillColor(context, 1.f, 1.f, 0.f, 1.f);
////    CGContextFillRect(context, rect)
//    
//    if (_images) {
//        NSArray<NSValue *> *sortedKeys = [_images.allKeys sortedArrayUsingComparator:^NSComparisonResult(NSValue * _Nonnull obj1, NSValue * _Nonnull obj2) {
//            CMTime obj1_time = obj1.CMTimeValue;
//            CMTime obj2_time = obj2.CMTimeValue;
//            
//            return [[NSNumber numberWithInteger:obj1_time.value] compare:[NSNumber numberWithInteger:obj2_time.value]];
//        }];
//        
//        CGFloat x = 0.f;
//        for (NSValue *key in sortedKeys) {
//            id image = _images[key];
//            CGImageRef imageRef = static_cast<CGImageRef>(image);
//            NSLog(@"%@", NSStringFromCGSize(CGSizeMake(CGImageGetWidth(imageRef), CGImageGetHeight(imageRef))));
////            CGFloat width = CGImageGetWidth(imageRef);
//            CGFloat height = CGImageGetHeight(imageRef);
//            
//            CGRect drawRect = CGRectMake(x, rect.origin.y, height, height);
//            CGContextDrawImage(context, drawRect, imageRef);
//            x += height;
//        }
//    }
//}
- (void)commonInit_EditorAssetPreviewView __attribute__((objc_direct)) {
    self.previewImages = @[];
}

- (void)drawRect:(CGRect)rect {
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    [self.previewImages enumerateObjectsUsingBlock:^(_EditorAssetPreviewImage * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        CGContextDrawImage(context, obj.rect, reinterpret_cast<CGImageRef>(obj.imageRef));
    }];
    
//    CGContextdr
    
//    self.previewImages = @[];
}

//- (void)drawLayer:(CALayer *)layer inContext:(CGContextRef)ctx {
//    [self.previewImages enumerateObjectsUsingBlock:^(_EditorAssetPreviewImage * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
//        CGContextDrawImage(ctx, obj.rect, reinterpret_cast<CGImageRef>(obj.imageRef));
//    }];
//    
//    self.previewImages = @[];
//}

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
    auto times = [NSMutableArray<NSValue *> new];
    
    std::for_each(frames.cbegin(), frames.cend(), [start, durationPerFrame, times](NSUInteger frame) {
        [times addObject:[NSValue valueWithCMTime:CMTimeMake(start.value + durationPerFrame * frame, start.timescale)]];
    });
    
    CALayer *layer = self.layer;
    
    [assetImageGenerator generateCGImagesAsynchronouslyForTimes:times completionHandler:^(CMTime requestedTime, CGImageRef  _Nullable image, CMTime actualTime, AVAssetImageGeneratorResult result, NSError * _Nullable error) {
        if (image) {
            NSInteger index = [times indexOfObject:[NSValue valueWithCMTime:requestedTime]];
            assert(index != NSNotFound);
            
            _EditorAssetPreviewImage *previewImage = [[_EditorAssetPreviewImage alloc] init];
            previewImage.rect = CGRectMake(itemWidth * index,
                                           0.f,
                                           itemWidth,
                                           itemHeight);
            previewImage.imageRef = static_cast<id>(image);
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                
                auto previewImages = reinterpret_cast<NSMutableArray<_EditorAssetPreviewImage *> *>([self.previewImages mutableCopy]);
                [previewImages addObject:previewImage];
                [previewImage release];
                self.previewImages = previewImages;
                
                [self setNeedsDisplay];
            });
            
//            id _image = (id)image;
//            
//            dispatch_async(dispatch_get_main_queue(), ^{
//                CGColorSpaceRef space = CGColorSpaceCreateWithName(kCGColorSpaceSRGB);
//                CGContextRef bitmapContext = CGBitmapContextCreate(NULL,
//                                                                   layer.bounds.size.width,
//                                                                   layer.bounds.size.height,
//                                                                   8,
//                                                                   0,
//                                                                   space,
//                                                                   kCGImageAlphaPremultipliedLast);
//                CGColorSpaceRelease(space);
//                
//                [layer renderInContext:bitmapContext];
//                
//                CGRect rect = CGRectMake(itemWidth * index,
//                                         0.f,
//                                         itemWidth,
//                                         itemHeight);
//                
//                auto imageRef = reinterpret_cast<CGImageRef>(_image);
//                CGContextDrawImage(bitmapContext, rect, reinterpret_cast<CGImageRef>(imageRef));
//                
//                if (index > 3) {
//                    CGImageRef tmpImageRef = CGBitmapContextCreateImage(bitmapContext);
//                    CGImageRelease(tmpImageRef);
//                }
//                
//                [layer drawInContext:bitmapContext];
//                
//                CGContextRelease(bitmapContext);
//            });
        }
    }];
    
    [times release];
    
    self.assetImageGenerator = assetImageGenerator;
    [assetImageGenerator release];
}

@end
