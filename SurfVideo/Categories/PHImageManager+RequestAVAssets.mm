//
//  PHImageManager+RequestAVAssets.mm
//  SurfVideo
//
//  Created by Jinwoo Kim on 12/11/23.
//

#import "PHImageManager+RequestAVAssets.hpp"
#import "PHPhotoLibrary+Private.h"

#define UNIT_COUNT 1000000ULL

__attribute__((objc_direct_members))
@interface _SVCachedAsset : NSObject
@property (retain, readonly, nonatomic) AVAsset * _Nullable avAsset;
@property (retain, readonly, nonatomic) AVAudioMix * _Nullable avAudioMix;
@property (retain, readonly, nonatomic) NSDictionary * _Nullable info;
@property (retain, readonly, nonatomic) PHAsset * _Nullable phAsset;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithAVAsset:(AVAsset * _Nullable)avAsset avAudioMix:(AVAudioMix * _Nullable)avAudioMix info:(NSDictionary * _Nullable)info phAsset:(PHAsset * _Nullable)phAsset;
@end

@implementation _SVCachedAsset

- (instancetype)initWithAVAsset:(AVAsset *)avAsset avAudioMix:(AVAudioMix *)avAudioMix info:(NSDictionary *)info phAsset:(PHAsset *)phAsset {
    if (self = [super init]) {
        _avAsset = [avAsset retain];
        _avAudioMix = [avAudioMix retain];
        _info = [info retain];
        _phAsset = [phAsset retain];
    }
    
    return self;
}

- (void)dealloc {
    [_avAsset release];
    [_avAudioMix release];
    [_info release];
    [_phAsset release];
    [super dealloc];
}

@end

@implementation PHImageManager (RequestAVAssets)

- (nonnull NSProgress *)sv_requestAVAssetsForAssetIdentifiers:(NSArray<NSString *> *)assetIdentifiers options:(PHVideoRequestOptions * _Nullable)options partialResultHandler:(nonnull void (^)(NSString * _Nullable assetIdentifier, AVAsset * _Nullable avAsset, AVAudioMix * _Nullable avAuioMix, NSDictionary * _Nullable info, PHAsset *asset, BOOL *stop, BOOL isEnd))partialResultHandler {
    assert(options.progressHandler == nil);
    assert(assetIdentifiers.count);
    
    NSProgress *progress = [NSProgress progressWithTotalUnitCount:assetIdentifiers.count * UNIT_COUNT];
    auto managedObjectContext = PHPhotoLibrary.sharedPhotoLibrary.managedObjectContext;
    
    [managedObjectContext performBlock:^{
        PHFetchOptions *fetchOptions = [PHFetchOptions new];
        fetchOptions.fetchLimit = assetIdentifiers.count;
        fetchOptions.includeHiddenAssets = YES;
        
        PHFetchResult<PHAsset *> *fetchResult = [PHAsset fetchAssetsWithLocalIdentifiers:assetIdentifiers options:fetchOptions];
        [fetchOptions release];
        
        auto cachedAssets = [NSMutableDictionary<NSString *, _SVCachedAsset *> new];
        
        [self sv_requestAVAssetForAssetIdentifiers:assetIdentifiers
                                       fetchResult:fetchResult
                                             index:0
                                      cachedAssets:cachedAssets
                                           options:options
                                          progress:progress 
                              partialResultHandler:partialResultHandler];
        
        [cachedAssets release];
    }];
    
    return progress;
}

- (void)sv_requestAVAssetForAssetIdentifiers:(NSArray<NSString *> *)assetIdentifiers
                                 fetchResult:(PHFetchResult<PHAsset *> *)fetchResult
                                       index:(NSUInteger)index
                                cachedAssets:(NSMutableDictionary<NSString *, _SVCachedAsset *> *)cachedAssets
                                     options:(PHVideoRequestOptions * _Nullable)options
                                    progress:(NSProgress *)progress
                        partialResultHandler:(nonnull void (^)(NSString * _Nullable assetIdentifier, AVAsset * _Nullable avAsset, AVAudioMix * _Nullable avAuioMix, NSDictionary * _Nullable info, PHAsset *asset, BOOL *stop, BOOL isEnd))partialResultHandler __attribute__((objc_direct)) {
    if (progress.isCancelled) {
        partialResultHandler(nil, nil, nil, @{PHImageCancelledKey: @YES}, nil, NULL, YES);
        return;
    }
    
    NSString *assetIdentifier = assetIdentifiers[index];
    const NSUInteger nextIndex = index + 1;
    
    if (auto cachedAsset = cachedAssets[assetIdentifier]) {
        progress.completedUnitCount += UNIT_COUNT;
        
        BOOL stop = NO;
        
        if (assetIdentifiers.count <= nextIndex) {
            partialResultHandler(assetIdentifier, cachedAsset.avAsset, cachedAsset.avAudioMix, cachedAsset.info, cachedAsset.phAsset, &stop, YES);
        } else {
            partialResultHandler(assetIdentifier, cachedAsset.avAsset, cachedAsset.avAudioMix, cachedAsset.info, cachedAsset.phAsset, &stop, NO);
            
            if (!stop) {
                [self sv_requestAVAssetForAssetIdentifiers:assetIdentifiers
                                               fetchResult:fetchResult
                                                     index:nextIndex
                                              cachedAssets:cachedAssets
                                                   options:options
                                                  progress:progress 
                                      partialResultHandler:partialResultHandler];
            }
        }
    } else {
        PHAsset *phAsset = nil;
        
        for (PHAsset *_phAsset in fetchResult) {
            if ([_phAsset.localIdentifier isEqualToString:assetIdentifier]) {
                phAsset = _phAsset;
                break;
            }
        }
        
        assert(phAsset != nil);
        
        NSProgress *childProgress = [NSProgress progressWithTotalUnitCount:UNIT_COUNT];
        [progress addChild:childProgress withPendingUnitCount:UNIT_COUNT];
        PHVideoRequestOptions *copiedOptions = [options copy];
        if (!copiedOptions) copiedOptions = [PHVideoRequestOptions new];
        
        copiedOptions.progressHandler = ^(double progress, NSError * _Nullable error, BOOL * _Nonnull stop, NSDictionary * _Nullable info) {
            childProgress.completedUnitCount = progress * UNIT_COUNT;
        };
        
        PHImageRequestID requestID = [self requestAVAssetForVideo:phAsset options:copiedOptions resultHandler:^(AVAsset * _Nullable avAsset, AVAudioMix * _Nullable avAudioMix, NSDictionary * _Nullable info) {
            BOOL isCancelled = static_cast<NSNumber *>(info[PHImageCancelledKey]).boolValue;
            BOOL stop = NO;
            
            if (isCancelled || assetIdentifiers.count <= nextIndex) {
                partialResultHandler(assetIdentifier, avAsset, avAudioMix, info, phAsset, &stop, YES);
            } else {
                _SVCachedAsset *cachedAsset = [[_SVCachedAsset alloc] initWithAVAsset:avAsset
                                                                           avAudioMix:avAudioMix
                                                                                 info:info
                                                                              phAsset:phAsset];
                cachedAssets[phAsset.localIdentifier] = cachedAsset;
                [cachedAsset release];
                
                partialResultHandler(assetIdentifier, avAsset, avAudioMix, info, phAsset, &stop, NO);
                
                if (!stop) {
                    [self sv_requestAVAssetForAssetIdentifiers:assetIdentifiers
                                                   fetchResult:fetchResult
                                                         index:nextIndex
                                                  cachedAssets:cachedAssets
                                                       options:options
                                                      progress:progress 
                                          partialResultHandler:partialResultHandler];
                }
            }
        }];
        
        childProgress.cancellationHandler = ^{
            [self cancelImageRequest:requestID];
        };
        
        [copiedOptions release];
    }
}

@end
