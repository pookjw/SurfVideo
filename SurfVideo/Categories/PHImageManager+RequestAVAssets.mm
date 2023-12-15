//
//  PHImageManager+RequestAVAssets.mm
//  SurfVideo
//
//  Created by Jinwoo Kim on 12/11/23.
//

#import "PHImageManager+RequestAVAssets.hpp"

@implementation PHImageManager (RequestAVAssets)

- (nonnull NSProgress *)sv_requestAVAssetsForFetchResult:(nonnull PHFetchResult<PHAsset *> *)assets options:(PHVideoRequestOptions * _Nullable)options partialResultHandler:(nonnull void (^)(AVAsset * _Nullable avAsset, AVAudioMix * _Nullable avAuioMix, NSDictionary * _Nullable info, PHAsset *asset, BOOL *stop, BOOL isEnd))partialResultHandler {
    assert(!options.progressHandler);
    assert(assets.count);
    
    NSProgress *progress = [NSProgress progressWithTotalUnitCount:assets.count * 1000000];
    
    [self sv_requestAVAssetsForVideos:assets options:options index:0 progress:progress partialResultHandler:partialResultHandler];
    
    return progress;
}

- (void)sv_requestAVAssetsForVideos:(nonnull PHFetchResult<PHAsset *> *)assets
                            options:(PHVideoRequestOptions * _Nullable)options
                              index:(NSUInteger)index
                           progress:(NSProgress *)progress
               partialResultHandler:(nonnull void (^)(AVAsset * _Nullable avAsset, AVAudioMix * _Nullable avAuioMix, NSDictionary * _Nullable info, PHAsset *asset, BOOL *stop, BOOL isEnd))partialResultHandler __attribute__((objc_direct)) {
    if (progress.isCancelled) {
        partialResultHandler(nil, nil, @{PHImageCancelledKey: @YES}, assets[index], NULL, YES);
        NS_VOIDRETURN;
    }
    
    NSProgress *childProgress = [NSProgress progressWithTotalUnitCount:1000000];
    [progress addChild:childProgress withPendingUnitCount:1000000];
    PHVideoRequestOptions *copiedOptions = [options copy];
    if (!copiedOptions) copiedOptions = [PHVideoRequestOptions new];
    
    copiedOptions.progressHandler = ^(double progress, NSError * _Nullable error, BOOL * _Nonnull stop, NSDictionary * _Nullable info) {
        childProgress.completedUnitCount = progress * 1000000.0;
    };
    
    PHImageRequestID requestID = [self requestAVAssetForVideo:assets[index] options:copiedOptions resultHandler:^(AVAsset * _Nullable asset, AVAudioMix * _Nullable audioMix, NSDictionary * _Nullable info) {
        BOOL isCancelled = static_cast<NSNumber *>(info[PHImageCancelledKey]).boolValue;
        const NSUInteger nextIndex = index + 1;
        BOOL stop = NO;
        
        if (isCancelled || assets.count <= nextIndex) {
            partialResultHandler(asset, audioMix, info, assets[index], &stop, YES);
        } else {
            partialResultHandler(asset, audioMix, info, assets[index], &stop, NO);
            
            if (!stop) {
                [self sv_requestAVAssetsForVideos:assets options:options index:index + 1 progress:progress partialResultHandler:partialResultHandler];
            }
        }
    }];
    
    childProgress.cancellationHandler = ^{
        [self cancelImageRequest:requestID];
    };
    
    [copiedOptions release];
}

@end
