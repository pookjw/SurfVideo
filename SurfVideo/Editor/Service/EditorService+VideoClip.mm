//
//  EditorService+VideoClip.mm
//  SurfVideo
//
//  Created by Jinwoo Kim on 2/29/24.
//

#import "EditorService+VideoClip.hpp"
#import "EditorService+Private.hpp"
#import "constants.hpp"
#import "PHImageManager+RequestAVAssets.hpp"

@implementation EditorService (VideoClip)

- (void)appendVideoClipsToMainVideoTrackFromPickerResults:(NSArray<PHPickerResult *> *)pickerResults 
                                          progressHandler:(void (^)(NSProgress * _Nonnull progress))progressHandler
                                        completionHandler:(EditorServiceCompletionHandler)completionHandler {
    assert(pickerResults.count > 0);
    
    dispatch_async(self.queue_1, ^{
        dispatch_suspend(self.queue_1);
        
        AVComposition * _Nullable composition = self.queue_composition;
        
        if (!composition) {
            completionHandler(nil, nil, nil, nil, nil, [NSError errorWithDomain:SurfVideoErrorDomain code:SurfVideoNotInitializedError userInfo:nil]);
            dispatch_resume(self.queue_1);
            return;
        }
        
        AVMutableComposition *mutableComposition = [composition mutableCopy];
        SVVideoProject *videoProject = self.queue_videoProject;
        NSDictionary<NSNumber *, NSArray<NSUUID *> *> *compositionIDs = self.queue_compositionIDs;
        CMPersistentTrackID mainVideoTrackID = self.mainVideoTrackID;
        NSArray<__kindof EditorRenderElement *> *renderElements = self.queue_renderElements;
        NSDictionary<NSUUID *, NSString *> *trackSegmentNamesByCompositionID = self.queue_trackSegmentNamesByCompositionID;
        NSManagedObjectContext *managedObjectContext = videoProject.managedObjectContext;
        
        NSArray<NSString *> *assetIdentifiers = [self assetIdentifiersFromPickerResults:pickerResults];
        
        NSMutableDictionary<NSString *, AVAsset *> *avAssetsByAssetIdentifier = [[NSMutableDictionary alloc] initWithCapacity:assetIdentifiers.count];
        NSMutableArray<AVAsset *> *avAssets = [[NSMutableArray alloc] initWithCapacity:assetIdentifiers.count];
        
        PHVideoRequestOptions *options = [PHVideoRequestOptions new];
        options.networkAccessAllowed = YES;
        options.deliveryMode = PHVideoRequestOptionsDeliveryModeHighQualityFormat;
        
        NSProgress *parentProgress = [NSProgress progressWithTotalUnitCount:pickerResults.count + 1];
        
        progressHandler(parentProgress);
        
        NSProgress *progress = [PHImageManager.defaultManager sv_requestAVAssetsForAssetIdentifiers:assetIdentifiers options:options partialResultHandler:^(NSString * _Nullable assetIdentifier, AVAsset * _Nullable avAsset, AVAudioMix * _Nullable avAuioMix, NSDictionary * _Nullable info, PHAsset * _Nonnull asset, BOOL * _Nonnull stop, BOOL isEnd) {
            if (static_cast<NSNumber *>(info[PHImageCancelledKey]).boolValue) {
                *stop = YES;
                completionHandler(nil, nil, nil, nil, nil, [NSError errorWithDomain:SurfVideoErrorDomain code:SurfVideoUserCancelledError userInfo:nil]);
                dispatch_resume(self.queue_1);
                return;
            }
            
            if (auto error = static_cast<NSError *>(info[PHImageErrorKey])) {
                *stop = YES;
                completionHandler(nil, nil, nil, nil, nil, error);
                dispatch_resume(self.queue_1);
                return;
            }
            
            avAssetsByAssetIdentifier[assetIdentifier] = avAsset;
            [avAssets addObject:avAsset];
            
            if (isEnd) {
                NSDictionary<AVAsset *, NSString *> *titlesByAVAsset = [self titlesFromAVAssets:avAssetsByAssetIdentifier.allValues];
                NSDictionary<NSString *, NSString *> *titlesByAssetIdentifier = [self titlesByAssetIdentifierWithAVAssetsByAssetIdentifier:avAssetsByAssetIdentifier titlesByAVAsset:titlesByAVAsset];
                
                [managedObjectContext performBlock:^{
                    NSError * _Nullable error = nil;
                    
                    NSDictionary<NSString *, id> *result = [self contextQueue_createSVClipsFromAssetIdentifiers:assetIdentifiers titlesByAssetIdentifier:titlesByAssetIdentifier videoProject:videoProject trackID:mainVideoTrackID error:&error];
                    
                    if (error != nil) {
                        completionHandler(nil, nil, nil, nil, nil, error);
                        dispatch_resume(self.queue_1);
                        return;
                    }
                    
                    AVMutableComposition *resultMutableComposition = [self appendClipsToTrackFromAVAssets:avAssets trackID:mainVideoTrackID mutableComposition:mutableComposition error:&error];
                    
                    if (error != nil) {
                        completionHandler(nil, nil, nil, nil, nil, error);
                        dispatch_resume(self.queue_1);
                        return;
                    }
                    
                    NSArray<NSUUID *> *createdCompositionIDArray = result[EditorServicePrivateCreatedCompositionIDArrayKey];
                    NSDictionary<NSUUID *, NSString *> *titlesByCompositionID = result[EditorServicePrivateTitlesByCompositionIDKey];
                    
                    NSMutableDictionary *newTrackSegmentNamesByCompositionID = [trackSegmentNamesByCompositionID mutableCopy];
                    [newTrackSegmentNamesByCompositionID addEntriesFromDictionary:titlesByCompositionID];
                    
                    [self contextQueue_finalizeWithVideoProject:videoProject
                                                    composition:resultMutableComposition
                                                 compositionIDs:[self appendingCompositionIDArray:createdCompositionIDArray trackID:mainVideoTrackID intoCompositionIDs:compositionIDs]
                               trackSegmentNamesByCompositionID:newTrackSegmentNamesByCompositionID 
                                                 renderElements:renderElements
                                              completionHandler:^(AVComposition * _Nullable composition, AVVideoComposition * _Nullable videoComposition, NSArray<__kindof EditorRenderElement *> * _Nullable renderElements, NSDictionary<NSUUID *,NSString *> * _Nullable trackSegmentNamesByCompositionID, NSDictionary<NSNumber *,NSArray<NSUUID *> *> * _Nullable compositionIDs, NSError * _Nullable error) {
                        parentProgress.completedUnitCount += 1;
                        assert(parentProgress.isFinished);
                        completionHandler(composition, videoComposition, renderElements, trackSegmentNamesByCompositionID, compositionIDs, nil);
                        dispatch_resume(self.queue_1);
                    }];
                    
                    [newTrackSegmentNamesByCompositionID release];
                }];
            }
        }];
        
        [parentProgress addChild:progress withPendingUnitCount:assetIdentifiers.count];
        
        [avAssetsByAssetIdentifier release];
        [avAssets release];
        [options release];
        
        [mutableComposition release];
    });
}

- (void)appendVideoClipsToMainVideoTrackFromURLs:(NSArray<NSURL *> *)URLs
                                 progressHandler:(void (^)(NSProgress * _Nonnull))progressHandler 
                               completionHandler:(EditorServiceCompletionHandler)completionHandler {
    [self appendClipsFromURLs:URLs intoTrackID:self.mainVideoTrackID progressHandler:progressHandler completionHandler:completionHandler];
}

- (void)removeVideoClipWithCompositionID:(NSUUID *)compositionID completionHandler:(EditorServiceCompletionHandler)completionHandler {
    [self removeClipWithCompositionID:compositionID completionHandler:completionHandler];
}

- (void)trimVideoClipWithCompositionID:(NSUUID *)compositionID 
                        assetStartTime:(CMTime)assetStartTime
                          assetEndTime:(CMTime)assetEndTime
                     completionHandler:(EditorServiceCompletionHandler)completionHandler {
    dispatch_async(self.queue_1, ^{
        dispatch_suspend(self.queue_1);
        
        AVMutableComposition *mutableComposition = [[self.queue_composition mutableCopy] autorelease];
        SVVideoProject *videoProject = self.queue_videoProject;
        NSDictionary<NSNumber *, NSArray<NSUUID *> *> *compositionIDs = self.queue_compositionIDs;
        CMPersistentTrackID mainVideoTrackID = self.mainVideoTrackID;
        NSArray<__kindof EditorRenderElement *> *renderElements = self.queue_renderElements;
        NSDictionary<NSUUID *, NSString *> *trackSegmentNamesByCompositionID = self.queue_trackSegmentNamesByCompositionID;
        NSManagedObjectContext *managedObjectContext = videoProject.managedObjectContext;
        
        NSInteger trackSegmentIndex = [compositionIDs[@(mainVideoTrackID)] indexOfObject:compositionID];
        assert(trackSegmentIndex != NSNotFound);
        
        AVMutableCompositionTrack *compositionTrack = [mutableComposition trackWithTrackID:mainVideoTrackID];
        
        NSArray<AVCompositionTrackSegment *> *oldSegments = compositionTrack.segments;
        
        NSIndexSet *affectedIndexes;
        if (trackSegmentIndex == oldSegments.count - 1) {
            affectedIndexes = [NSIndexSet indexSet];
        } else {
            affectedIndexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(trackSegmentIndex + 1, oldSegments.count - trackSegmentIndex - 1)];
        }
        
        NSArray<AVCompositionTrackSegment *> *affectedSegments = [oldSegments objectsAtIndexes:affectedIndexes];
        AVCompositionTrackSegment *toBeTrimmedSegment = oldSegments[trackSegmentIndex];
        
        AVURLAsset *toBeTrimmedAsset = [AVURLAsset assetWithURL:toBeTrimmedSegment.sourceURL];
        
        NSError * _Nullable error = nil;
        
        [compositionTrack removeTimeRange:CMTimeRangeMake(toBeTrimmedSegment.timeMapping.target.start, CMTimeRangeGetEnd(compositionTrack.timeRange))];
        
        for (AVAssetTrack *assetTrack in toBeTrimmedAsset.tracks) {
            if ([assetTrack.mediaType isEqualToString:AVMediaTypeVideo]) {
                [compositionTrack insertTimeRange:CMTimeRangeMake(assetStartTime, CMTimeSubtract(assetEndTime, assetStartTime))
                                          ofTrack:assetTrack
                                           atTime:CMTimeRangeGetEnd(compositionTrack.timeRange)
                                            error:&error];
                break;
            }
        }
        
        if (error != nil) {
            completionHandler(nil, nil, nil, nil, nil, error);
            dispatch_resume(self.queue_1);
            return;
        }
        
        for (AVCompositionTrackSegment *affectedSegment in affectedSegments) {
            AVURLAsset *asset = [AVURLAsset assetWithURL:affectedSegment.sourceURL];
            
            for (AVAssetTrack *assetTrack in asset.tracks) {
                if ([assetTrack.mediaType isEqualToString:AVMediaTypeVideo]) {
                    [compositionTrack insertTimeRange:affectedSegment.timeMapping.source
                                              ofTrack:assetTrack
                                               atTime:CMTimeRangeGetEnd(compositionTrack.timeRange)
                                                error:&error];
                    break;
                }
            }
            
            if (error != nil) {
                completionHandler(nil, nil, nil, nil, nil, error);
                dispatch_resume(self.queue_1);
                return;
            }
        }
        
        //
        
        [managedObjectContext performBlock:^{
            [self contextQueue_finalizeWithVideoProject:videoProject
                                            composition:mutableComposition
                                         compositionIDs:compositionIDs
                       trackSegmentNamesByCompositionID:trackSegmentNamesByCompositionID
                                         renderElements:renderElements
                                      completionHandler:EditorServiceCompletionHandlerBlock {
                completionHandler(composition, videoComposition, renderElements, trackSegmentNamesByCompositionID, compositionIDs, nil);
                dispatch_resume(self.queue_1);
            }];
        }];
    });
}

@end
