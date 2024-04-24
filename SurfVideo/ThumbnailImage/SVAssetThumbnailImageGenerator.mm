//
//  SVAssetThumbnailImageGenerator.mm
//  SurfVideo
//
//  Created by Jinwoo Kim on 4/24/24.
//

#import "SVAssetThumbnailImageGenerator.hpp"
#import "_SVAssetThumbnailImageCache.hpp"
#import "_SVAssetThumbnailImageRequest.hpp"
#import "constants.hpp"
#import <UIKit/UIKit.h>

__attribute__((objc_direct_members))
@interface SVAssetThumbnailImageGenerator ()
@property (retain, readonly, nonatomic) dispatch_queue_t queue;
@property (retain, readonly, nonatomic) NSMutableDictionary<NSUUID *, NSMutableArray<_SVAssetThumbnailImageCache *> *> *queue_imageCachesByAssetID;
@property (retain, readonly, nonatomic) NSMutableArray<_SVAssetThumbnailImageRequest *> *queue_requests;
@end

@implementation SVAssetThumbnailImageGenerator

- (instancetype)init {
    if (self = [super init]) {
        dispatch_queue_attr_t attr = dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, QOS_CLASS_USER_INITIATED, QOS_MIN_RELATIVE_PRIORITY);
        
        _queue = dispatch_queue_create("SVAssetThumbnailImageGenerator", attr);
        _queue_imageCachesByAssetID = [NSMutableDictionary new];
        _queue_requests = [NSMutableArray new];
        
        [NSNotificationCenter.defaultCenter addObserver:self 
                                               selector:@selector(applicationDidReceiveMemoryWarningNotification:)
                                                   name:UIApplicationDidReceiveMemoryWarningNotification 
                                                 object:nil];
    }
    
    return self;
}

- (void)dealloc {
    if (auto queue = _queue) {
        dispatch_release(queue);
    }
    
    [_queue_imageCachesByAssetID release];
    [_queue_requests release];
    
    [NSNotificationCenter.defaultCenter removeObserver:self
                                                  name:UIApplicationDidReceiveMemoryWarningNotification
                                                object:nil];
    
    [super dealloc];
}

// Cancel 할 때, 만약에 1, 2, 3 시간을 요청했고 2, 3, 4, 5를 요청했는데 첫 작업을 취소하면, 뒷 작업은 취소되지 않았는데 2, 3을 못 받는 문제가 생김
// TODO: 대충 근접한 시간이면 Cache 얻어오는 기능, Progress unit count, Memory Warning, Cell에서 화면만큼만 (UICoordinateSpace), Track에서 Generator 만들어서 전달하기, 아래 Retain Cycle 어떻게 해결할지

- (NSProgress *)requestThumbnailImagesFromAsset:(AVAsset *)asset assetID:(NSUUID *)assetID atTimes:(NSOrderedSet<NSValue *> *)times maximumSize:(CGSize)maximumSize requestHandler:(void (^)(CMTime, CMTime, CGImageRef _Nullable, NSError * _Nullable, BOOL))requestHandler {
    NSUInteger timesCount = times.count;
    
    if (timesCount == 0) {
        return nil;
    }
    
    NSProgress *progress = [NSProgress progressWithTotalUnitCount:timesCount];
    
    dispatch_async(_queue, ^{
        NSOrderedSet<NSValue *> *uncachedTimes_1 = [self queue_removingCachedTimesFromTimes:times
                                                                                      asset:asset
                                                                                    assetID:assetID
                                                                                maximumSize:maximumSize
                                                                                   progress:progress
                                                                              cachedHandler:requestHandler];
        
        if (uncachedTimes_1.count == 0) {
            return;
        }
        
        NSOrderedSet<NSValue *> *uncachedTimes_2 = [self queue_removingRequestingTimesFromTimes:times
                                                                                          asset:asset
                                                                                        assetID:assetID
                                                                                    maximumSize:maximumSize
                                                                                       progress:progress
                                                                                 requestHandler:requestHandler];
        
        if (uncachedTimes_2.count == 0) {
            return;
        }
        
        //
        
        [self queue_registerRequestFromAsset:asset
                                     assetID:assetID
                                     atTimes:uncachedTimes_2
                                 maximumSize:maximumSize
                                    progress:progress
                              requestHandler:requestHandler];
    });
    
    return progress;
}

- (NSOrderedSet *)queue_removingCachedTimesFromTimes:(NSOrderedSet<NSValue *> *)times asset:(AVAsset *)asset assetID:(NSUUID *)assetID maximumSize:(CGSize)maximumSize progress:(NSProgress *)progress cachedHandler:(void (^)(CMTime, CMTime, CGImageRef _Nullable, NSError * _Nullable, BOOL))cachedHandler __attribute__((objc_direct)) {
    if (auto imageCaches = self.queue_imageCachesByAssetID[assetID]) {
        NSMutableOrderedSet *uncahcedTimes = [times mutableCopy];
        
        [imageCaches enumerateObjectsUsingBlock:^(_SVAssetThumbnailImageCache * _Nonnull imageCache, NSUInteger idx, BOOL * _Nonnull stop) {
            NSValue *cahcedRequestedTime = [NSValue valueWithCMTime:imageCache.requestedTime];
            
            if ([times containsObject:cahcedRequestedTime] && CGSizeEqualToSize(maximumSize, imageCache.maximumSize)) {
                BOOL finished = (uncahcedTimes.count == 0);
                cachedHandler(imageCache.requestedTime, imageCache.actualTime, imageCache.image, nil, finished);
                [uncahcedTimes removeObject:cahcedRequestedTime];
                
                progress.completedUnitCount += 1;
                
                if (finished) {
                    *stop = YES;
                }
            }
        }];
        
        return [uncahcedTimes autorelease];
    } else {
        return times;
    }
}

- (NSOrderedSet *)queue_removingRequestingTimesFromTimes:(NSOrderedSet<NSValue *> *)times asset:(AVAsset *)asset assetID:(NSUUID *)assetID maximumSize:(CGSize)maximumSize progress:(NSProgress *)progress requestHandler:(void (^)(CMTime, CMTime, CGImageRef _Nullable, NSError * _Nullable, BOOL))requestHandler __attribute__((objc_direct)) {
    NSMutableOrderedSet *notRequestingTimes = [times mutableCopy];
    
    for (_SVAssetThumbnailImageRequest *request in self.queue_requests) {
        if (![request.assetID isEqual:assetID]) continue;
        
        [times enumerateObjectsUsingBlock:^(NSValue * _Nonnull timeValue, NSUInteger idx, BOOL * _Nonnull stop) {
            if (auto completionBlocks = request.completionBlocksByTime[timeValue]) {
                [completionBlocks addObject:(id)requestHandler];
                [notRequestingTimes removeObject:timeValue];
                
                progress.completedUnitCount += 1;
                
                if (notRequestingTimes.count == 0) {
                    *stop = YES;
                }
            }
        }];
        
        if (notRequestingTimes.count == 0) {
            break;
        }
    }
    
    return [notRequestingTimes autorelease];
}

- (_SVAssetThumbnailImageRequest * _Nullable)queue_registerRequestFromAsset:(AVAsset *)asset assetID:(NSUUID *)assetID atTimes:(NSOrderedSet<NSValue *> *)times maximumSize:(CGSize)maximumSize progress:(NSProgress *)progress requestHandler:(void (^)(CMTime, CMTime, CGImageRef _Nullable, NSError * _Nullable, BOOL))requestHandler __attribute__((objc_direct)) {
    
    if (progress.isCancelled) {
        return nil;
    }
    
    AVAssetImageGenerator *assetImageGenerator = [AVAssetImageGenerator assetImageGeneratorWithAsset:asset];
    assetImageGenerator.maximumSize = maximumSize;
    assetImageGenerator.appliesPreferredTrackTransform = YES;
    
    _SVAssetThumbnailImageRequest *request = [[_SVAssetThumbnailImageRequest alloc] initWithAssetID:assetID
                                                                                assetImageGenerator:assetImageGenerator
                                                                                              times:times
                                                                                        maximumSize:maximumSize];
    
    NSMutableSet<NSValue *> *remainingTimes = [NSMutableSet setWithArray:times.array];
    NSUInteger timesCount = times.count;
    
    id completionBlock = [^(CMTime requestedTime, CMTime actualTime, CGImageRef _Nullable image, NSError * _Nullable error) {
        NSValue *timeValue = [NSValue valueWithCMTime:requestedTime];
        
        //
        
        assert(remainingTimes != nil);
        [remainingTimes removeObject:timeValue];
        BOOL finished = (remainingTimes.count == 0);
        
        requestHandler(requestedTime, actualTime, image, error, finished);
        progress.completedUnitCount += 1;
        
        if (finished) {
            assert(progress.isFinished);
            
            // TODO: Retain Cycle
            [self.queue_requests removeObject:request];
        }
    } copy];
    
    NSMutableDictionary *subcompletionBlocks = [[NSMutableDictionary alloc] initWithCapacity:timesCount];
    
    for (NSValue *time in times) {
        subcompletionBlocks[time] = [NSMutableArray arrayWithObject:completionBlock];
    }
    
    [completionBlock release];
    [request.completionBlocksByTime addEntriesFromDictionary:subcompletionBlocks];
    [subcompletionBlocks release];
    
    [self.queue_requests addObject:request];
    
    [assetImageGenerator generateCGImagesAsynchronouslyForTimes:times.array
                                              completionHandler:^(CMTime requestedTime, CGImageRef  _Nullable image, CMTime actualTime, AVAssetImageGeneratorResult result, NSError * _Nullable error) {
        id imageObj = static_cast<id>(image);
        
        dispatch_async(_queue, ^{
            CGImageRef image = static_cast<CGImageRef>(imageObj);
            
            //
            
            if (image != NULL) {
                NSMutableArray *imageCaches = self.queue_imageCachesByAssetID[assetID];
                if (imageCaches == nil) {
                    imageCaches = [NSMutableArray array];
                    self.queue_imageCachesByAssetID[assetID] = imageCaches;
                }
                
                // TODO: Check
                //        assert(imageCachesByTime[timeValue] == nil);
                
                _SVAssetThumbnailImageCache *imageCache = [[_SVAssetThumbnailImageCache alloc] initWithAssetID:assetID
                                                                                                 requestedTime:requestedTime
                                                                                                    actualTime:actualTime
                                                                                                         image:image
                                                                                                   maximumSize:maximumSize];
                
                [imageCaches addObject:imageCache];
                [imageCache release];
            }
            
            //
            
            NSValue *requestedTimeValue = [NSValue valueWithCMTime:requestedTime];
            
            NSError * _Nullable _error;
            if (error) {
                _error = error;
            } else if (result == AVAssetImageGeneratorCancelled) {
                _error = [NSError errorWithDomain:SurfVideoErrorDomain code:SurfVideoUserCancelledError userInfo:nil];
            } else {
                _error = nil;
            }
            
            auto completionBlocks = request.completionBlocksByTime[requestedTimeValue];
            
            [completionBlocks enumerateObjectsUsingBlock:^(void (^ _Nonnull completionBlock)(CMTime, CMTime, CGImageRef _Nullable, NSError * _Nullable), NSUInteger idx, BOOL * _Nonnull stop) {
                completionBlock(requestedTime, actualTime, image, _error);
            }];
            
            [request.completionBlocksByTime removeObjectForKey:requestedTimeValue];
        });
    }];
    
    progress.cancellationHandler = ^{
        [assetImageGenerator cancelAllCGImageGeneration];
    };
    
    return [request autorelease];
}

- (void)applicationDidReceiveMemoryWarningNotification:(NSNotification *)notification {
    dispatch_async(_queue, ^{
        [self.queue_imageCachesByAssetID removeAllObjects];
    });
}

@end
