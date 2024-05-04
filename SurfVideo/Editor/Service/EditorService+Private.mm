//
//  EditorService+Private.mm
//  SurfVideo
//
//  Created by Jinwoo Kim on 3/1/24.
//

#import "EditorService+Private.hpp"
#import "constants.hpp"
#import "PHImageManager+RequestAVAssets.hpp"
#import "SVProjectsManager.hpp"
#import "ImageUtils.hpp"
#import "NSObject+KeyValueObservation.h"
#import "SVRunLoop.hpp"
#import "NSManagedObjectContext+CheckThread.hpp"
#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>

@implementation EditorService (Private)

- (dispatch_queue_t)queue_1 {
    return _queue_1;
}

- (dispatch_queue_t)queue_2 {
    return _queue_2;
}

- (void)assertQueue {
#if DEBUG
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    dispatch_queue_t current_queue = dispatch_get_current_queue();
#pragma clang diagnostic pop
    
    assert((current_queue == _queue_1) || (current_queue == _queue_2));
#endif
}

- (SVVideoProject *)queue_videoProject {
    [self assertQueue];

    return _queue_videoProject;
}

- (void)queue_setVideoProject:(SVVideoProject *)queue_videoProject {
    [self assertQueue];
    
    [_queue_videoProject release];
    _queue_videoProject = [queue_videoProject retain];
}

- (NSSet<NSUserActivity *> *)userActivities {
    return _userActivities;
}

- (AVComposition *)queue_composition {
    [self assertQueue];
    
    return _queue_composition;
}

- (void)queue_setComposition:(AVComposition *)queue_composition {
    [self assertQueue];
    
    [_queue_composition release];
    _queue_composition = [queue_composition copy];
}

- (AVVideoComposition *)queue_videoComposition {
    [self assertQueue];
    
    return _queue_videoComposition;
}

- (void)queue_setVideoComposition:(AVVideoComposition *)queue_videoComposition {
    [self assertQueue];
    
    [_queue_videoComposition release];
    _queue_videoComposition = [queue_videoComposition copy];
}

- (NSArray<__kindof EditorRenderElement *> *)queue_renderElements {
    [self assertQueue];
    
    return _queue_renderElements;
}

- (void)queue_setRenderElements:(NSArray<__kindof EditorRenderElement *> *)queue_renderElements {
    [self assertQueue];
    
    [_queue_renderElements release];
    _queue_renderElements = [queue_renderElements copy];
}

- (NSDictionary<NSUUID *,NSString *> *)queue_trackSegmentNamesByCompositionID {
    [self assertQueue];
    
    return _queue_trackSegmentNamesByCompositionID;
}

- (void)queue_setTackSegmentNamesByCompositionID:(NSDictionary<NSUUID *,NSString *> *)queue_trackSegmentNamesByCompositionID {
    [self assertQueue];
    
    [_queue_trackSegmentNamesByCompositionID release];
    _queue_trackSegmentNamesByCompositionID = [queue_trackSegmentNamesByCompositionID copy];
}

- (NSDictionary<NSNumber *, NSArray<NSUUID *> *> *)queue_compositionIDs {
    [self assertQueue];
    
    return _queue_compositionIDs;
}

- (void)queue_setCompositionIDs:(NSDictionary<NSNumber *, NSArray<NSUUID *> *> *)queue_compositionIDs {
    [self assertQueue];
    
    [_queue_compositionIDs release];
    _queue_compositionIDs = [queue_compositionIDs copy];
}

- (void)queue_videoProjectWithCompletionHandler:(void (^)(SVVideoProject * _Nullable videoProject, NSError * _Nullable error))completionHandler {
    if (auto videoProject = self.queue_videoProject) {
        completionHandler(videoProject, nil);
        return;
    }
    
    NSURL * _Nullable uriRepresentation = nil;
    
    for (NSUserActivity *userActivity in _userActivities) {
        if ([userActivity.activityType isEqualToString:kEditorWindowSceneUserActivityType]) {
            uriRepresentation = userActivity.userInfo[EditorWindowUserActivityVideoProjectURIRepresentationKey];
            break;
        }
    }
    
    if (!uriRepresentation) {
        completionHandler(nil, [NSError errorWithDomain:SurfVideoErrorDomain code:SurfVideoNoURIRepresentationError userInfo:nil]);
        return;
    }
    
    //
    
    [SVProjectsManager.sharedInstance managedObjectContextWithCompletionHandler:^(NSManagedObjectContext * _Nullable managedObjectContext) {
        [managedObjectContext performBlock:^{
            NSManagedObjectID *objectID = [managedObjectContext.persistentStoreCoordinator managedObjectIDForURIRepresentation:uriRepresentation];
            SVVideoProject *videoProject = [managedObjectContext objectWithID:objectID];
            assert(videoProject != nil);
            completionHandler(videoProject, nil);
        }];
    }];
}

- (void)contextQueue_mutableCompositionFromVideoProject:(SVVideoProject *)videoProject progressHandler:(void (^)(NSProgress *progress))progressHandler completionHandler:(void (^)(AVMutableComposition * _Nullable mutableComposition, NSDictionary<NSNumber *, NSArray<NSUUID *> *> * _Nullable compositionIDs, NSDictionary<NSUUID *, NSString *> * _Nullable trackSegmentNamesByCompositionID, NSError * _Nullable error))completionHandler {
    
    AVMutableComposition *mutableComposition = [AVMutableComposition composition];
    mutableComposition.naturalSize = CGSizeMake(1280.f, 720.f);
    [mutableComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:self.mainVideoTrackID];
    [mutableComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:self.audioTrackID];
    
    NSMutableDictionary<NSNumber *, NSMutableArray<NSUUID *> *> *compositionIDs = [NSMutableDictionary dictionary];
    NSMutableDictionary<NSUUID *, NSString *> *trackSegmentNamesByCompositionID = [NSMutableDictionary dictionary];
    
    NSOrderedSet<SVVideoClip *> *videoClips = videoProject.videoTrack.videoClips;
    NSOrderedSet<SVAudioClip *> *audioClips = videoProject.audioTrack.audioClips;
    
    NSProgress *progress = [NSProgress progressWithTotalUnitCount:videoClips.count + audioClips.count];
    progressHandler(progress);
    
    [self contextQueue_appendClipsToTrackFromClips:videoClips
                                           trackID:self.mainVideoTrackID
                                      videoProject:videoProject
                                mutableComposition:mutableComposition
                                    compositionIDs:compositionIDs
                  trackSegmentNamesByCompositionID:trackSegmentNamesByCompositionID
                                     createFootage:NO
                                             index:0
                                    parentProgress:progress
                                 completionHandler:^(AVMutableComposition * _Nullable mutableComposition, NSMutableDictionary<NSNumber *, NSMutableArray<NSUUID *> *> * _Nullable compositionIDs, NSMutableDictionary<NSUUID *, NSString *> * _Nullable trackSegmentNamesByCompositionID, NSError * _Nullable error) {
        if (error) {
            completionHandler(nil, nil, nil, error);
            return;
        }
        
        [self contextQueue_appendClipsToTrackFromClips:audioClips
                                               trackID:self.audioTrackID
                                          videoProject:videoProject
                                    mutableComposition:mutableComposition
                                        compositionIDs:compositionIDs
                      trackSegmentNamesByCompositionID:trackSegmentNamesByCompositionID
                                         createFootage:NO
                                                 index:0 parentProgress:progress
                                     completionHandler:^(AVMutableComposition * _Nullable mutableComposition, NSMutableDictionary<NSNumber *, NSMutableArray<NSUUID *> *> * _Nullable compositionIDs, NSMutableDictionary<NSUUID *, NSString *> * _Nullable trackSegmentNamesByCompositionID, NSError * _Nullable error) {
            if (error) {
                completionHandler(nil, nil, nil, error);
                return;
            }
            
            completionHandler(mutableComposition, compositionIDs, trackSegmentNamesByCompositionID, error);
        }];
    }];
}

- (NSDictionary<NSString *,id> *)contextQueue_createSVClipsFromAssetIdentifiers:(NSArray<NSString *> *)assetIdentifiers titlesByAssetIdentifier:(NSDictionary<NSString *, NSString *> *)titlesByAssetIdentifier videoProject:(SVVideoProject *)videoProject trackID:(CMPersistentTrackID)trackID error:(NSError * _Nullable *)error {
    NSManagedObjectContext *managedObjectContext = videoProject.managedObjectContext;
    
    NSDictionary<NSString *,SVPHAssetFootage *> *phAssetFootagesByAssetIdentifier = [SVProjectsManager.sharedInstance contextQueue_phAssetFootagesFromAssetIdentifiers:assetIdentifiers createIfNeededWithoutSaving:YES managedObjectContext:managedObjectContext error:error];
    
    if (*error) {
        return nil;
    }
    
    NSUInteger assetIdentifiersCount = assetIdentifiers.count;
    
    NSMutableDictionary<NSString *, NSUUID *> *createdCompositionIDsByAssetIdentifier = [[[NSMutableDictionary alloc] initWithCapacity:assetIdentifiersCount] autorelease];
    NSMutableArray<NSUUID *> *createdCompositionIDArray = [[[NSMutableArray alloc] initWithCapacity:assetIdentifiersCount] autorelease];
    NSMutableDictionary<NSUUID *, NSString *> *titlesByCompositionID = [NSMutableDictionary dictionary];
    
    //
    
    if (trackID == self.mainVideoTrackID) {
        SVVideoTrack *mainVideoTrack = videoProject.videoTrack;
        
        for (NSString *assetIdentifier in assetIdentifiers) {
            SVVideoClip *videoClip = [[SVVideoClip alloc] initWithContext:managedObjectContext];
            NSUUID *compositionID = [NSUUID UUID];
            NSString *title = titlesByAssetIdentifier[assetIdentifier];
            
            videoClip.footage = phAssetFootagesByAssetIdentifier[assetIdentifier];
            videoClip.name = title;
            videoClip.compositionID = compositionID;
            
            [mainVideoTrack addVideoClipsObject:videoClip];
            [videoClip release];
            
            [createdCompositionIDArray addObject:compositionID];
            titlesByCompositionID[compositionID] = title;
        }
    } else if (trackID == self.audioTrackID) {
        SVAudioTrack *audioTrack = videoProject.audioTrack;
        
        for (NSString *assetIdentifier in assetIdentifiers) {
            SVAudioClip *audioClip = [[SVAudioClip alloc] initWithContext:managedObjectContext];
            NSUUID *compositionID = [NSUUID UUID];
            NSString *title = titlesByAssetIdentifier[assetIdentifier];
            
            audioClip.footage = phAssetFootagesByAssetIdentifier[assetIdentifier];
            audioClip.name = title;
            audioClip.compositionID = compositionID;
            
            [audioTrack addAudioClipsObject:audioClip];
            [audioClip release];
            
            [createdCompositionIDArray addObject:compositionID];
            titlesByCompositionID[compositionID] = title;
        }
    } else {
        abort();
    }
    
    [managedObjectContext save:error];
    if (*error) {
        return nil;
    }
    
    return @{
        @"createdCompositionIDsByAssetIdentifier": createdCompositionIDsByAssetIdentifier,
        @"createdCompositionIDArray": createdCompositionIDArray,
        @"titlesByCompositionID": titlesByCompositionID
    };
}

- (NSDictionary<NSString *,id> *)contextQueue_createSVClipsFromSourceURLs:(NSArray<NSURL *> *)sourceURLs videoProject:(SVVideoProject *)videoProject trackID:(CMPersistentTrackID)trackID error:(NSError * _Nullable *)error {
    NSManagedObjectContext *managedObjectContext = videoProject.managedObjectContext;
    
    NSDictionary<NSURL *,SVLocalFileFootage *> *localFillFootagesBySourceURL = [SVProjectsManager.sharedInstance contextQueue_localFileFootageFromURLs:sourceURLs createIfNeededWithoutSaving:YES managedObjectContext:managedObjectContext error:error];
    
    if (*error) {
        return nil;
    }
    
    NSUInteger sourceURLsCount = sourceURLs.count;
    
    NSMutableDictionary<NSURL *, NSUUID *> *createdCompositionIDsBySourceURL = [[[NSMutableDictionary alloc] initWithCapacity:sourceURLsCount] autorelease];
    NSMutableArray<NSUUID *> *createdCompositionIDArray = [[[NSMutableArray alloc] initWithCapacity:sourceURLsCount] autorelease];
    NSMutableDictionary<NSURL *, NSURL *> *footageURLsBySourceURL = [[[NSMutableDictionary alloc] initWithCapacity:sourceURLsCount] autorelease];
    NSMutableArray<NSURL *> *footageURLArray = [[[NSMutableArray alloc] initWithCapacity:sourceURLsCount] autorelease];
    NSMutableDictionary<NSURL *, NSString *> *titlesBySourceURL = [NSMutableDictionary dictionary];
    NSMutableDictionary<NSUUID *, NSString *> *titlesByCompositionID = [NSMutableDictionary dictionary];
    
    //
    
    for (NSURL *sourceURL in sourceURLs) {
        SVLocalFileFootage *localFileFootage = localFillFootagesBySourceURL[sourceURL];
        NSURL *footageURL = [SVProjectsManager.sharedInstance.localFileFootagesURL URLByAppendingPathComponent:localFileFootage.fileName];
        footageURLsBySourceURL[sourceURL] = footageURL;
        [footageURLArray addObject:footageURL];
    }
    
    //
    
    for (NSURL *sourceURL in sourceURLs) {
        AVURLAsset *avAsset = [AVURLAsset assetWithURL:sourceURL];
        
        NSString * _Nullable title = nil;
        for (AVMetadataItem *metadataItem in avAsset.metadata) {
            if ([metadataItem.commonKey isEqualToString:AVMetadataCommonKeyTitle]) {
                title = static_cast<NSString *>(metadataItem.value);
                break;
            }
        }
        
        if (title == nil) {
            title = sourceURL.lastPathComponent;
        }
        
        titlesBySourceURL[sourceURL] = title;
    }
    
    //
    
    if (trackID == self.mainVideoTrackID) {
        SVVideoTrack *mainVideoTrack = videoProject.videoTrack;
        
        for (NSURL *sourceURL in sourceURLs) {
            SVVideoClip *videoClip = [[SVVideoClip alloc] initWithContext:managedObjectContext];
            NSUUID *compositionID = [NSUUID UUID];
            NSString *title = titlesBySourceURL[sourceURL];
            
            videoClip.footage = localFillFootagesBySourceURL[sourceURL];
            videoClip.name = title;
            videoClip.compositionID = compositionID;
            
            [mainVideoTrack addVideoClipsObject:videoClip];
            [videoClip release];
            
            createdCompositionIDsBySourceURL[sourceURL] = compositionID;
            [createdCompositionIDArray addObject:compositionID];
            titlesByCompositionID[compositionID] = title;
        }
    } else if (trackID == self.audioTrackID) {
        SVAudioTrack *audioTrack = videoProject.audioTrack;
        
        for (NSURL *sourceURL in sourceURLs) {
            SVAudioClip *audioClip = [[SVAudioClip alloc] initWithContext:managedObjectContext];
            NSUUID *compositionID = [NSUUID UUID];
            NSString *title = titlesBySourceURL[sourceURL];
            
            audioClip.footage = localFillFootagesBySourceURL[sourceURL];
            audioClip.name = title;
            audioClip.compositionID = compositionID;
            
            [audioTrack addAudioClipsObject:audioClip];
            [audioClip release];
            
            createdCompositionIDsBySourceURL[sourceURL] = compositionID;
            [createdCompositionIDArray addObject:compositionID];
            titlesByCompositionID[compositionID] = title;
        }
    }
    
    [managedObjectContext save:error];
    if (*error) {
        return nil;
    }
    
    return @{
        @"createdCompositionIDsBySourceURL": createdCompositionIDsBySourceURL,
        @"createdCompositionIDArray": createdCompositionIDArray,
        @"footageURLsBySourceURL": footageURLsBySourceURL,
        @"footageURLArray": footageURLArray,
        @"titlesBySourceURL": titlesBySourceURL,
        @"titlesByCompositionID": titlesByCompositionID
    };
}

- (AVMutableComposition *)appendClipsToTrackFromURLs:(NSArray<NSURL *> *)urls trackID:(CMPersistentTrackID)trackID mutableComposition:(AVMutableComposition *)mutableComposition error:(NSError * _Nullable *)error {
    NSMutableArray<AVURLAsset *> *avAssets = [[[NSMutableArray alloc] initWithCapacity:urls.count] autorelease];
    
    for (NSURL *url in urls) {
        AVURLAsset *avAsset = [AVURLAsset assetWithURL:url];
        [avAssets addObject:avAsset];
    }
    
    return [self appendClipsToTrackFromAVAssets:avAssets trackID:trackID mutableComposition:mutableComposition error:error];
}

- (AVMutableComposition * _Nullable)appendClipsToTrackFromAVAssets:(NSArray<AVAsset *> *)avAssets trackID:(CMPersistentTrackID)trackID mutableComposition:(AVMutableComposition *)mutableComposition error:(NSError * _Nullable * _Nullable)error {
    AVMutableCompositionTrack *compositionTrack = [mutableComposition trackWithTrackID:trackID];
    
    if (compositionTrack == nil) {
        if (error) {
            *error = [NSError errorWithDomain:SurfVideoErrorDomain code:SurfVideoNoTrackFoundError userInfo:nil];
        }
        
        return nil;
    }
    
    if (trackID == self.mainVideoTrackID) {
        for (AVAsset *avAsset in avAssets) {
            for (AVAssetTrack *assetTrack in avAsset.tracks) {
                if ([assetTrack.mediaType isEqualToString:AVMediaTypeVideo]) {
                    [compositionTrack insertTimeRange:assetTrack.timeRange ofTrack:assetTrack atTime:compositionTrack.timeRange.duration error:error];
                    
                    if (*error) {
                        return nil;
                    }
                }
            }
        }
    } else if (trackID == self.audioTrackID) {
        for (AVAsset *avAsset in avAssets) {
            for (AVAssetTrack *assetTrack in avAsset.tracks) {
                if ([assetTrack.mediaType isEqualToString:AVMediaTypeAudio]) {
                    [compositionTrack insertTimeRange:assetTrack.timeRange ofTrack:assetTrack atTime:compositionTrack.timeRange.duration error:error];
                    
                    if (*error) {
                        return nil;
                    }
                }
            }
        }
    } else {
        if (error) {
            *error = [NSError errorWithDomain:SurfVideoErrorDomain code:SurfVideoUnknownTrackID userInfo:nil];
        }
        return nil;
    }
    
    return mutableComposition;
}

- (void)queue_removeTrackSegmentWithCompositionID:(NSUUID *)compositionID mutableComposition:(AVMutableComposition *)mutableComposition compositionIDs:(NSDictionary<NSNumber *,NSArray<NSUUID *> *> *)compositionIDs trackSegmentNamesByCompositionID:(NSDictionary<NSUUID *, NSString *> *)trackSegmentNamesByCompositionID completionHandler:(void (^)(AVMutableComposition * _Nullable mutableComposition, NSDictionary<NSNumber *, NSArray<NSUUID *> *> * _Nullable compositionIDs, NSDictionary<NSUUID *, NSString *> *trackSegmentNamesByCompositionID, NSError * _Nullable error))completionHandler {
    __block CMPersistentTrackID trackID = kCMPersistentTrackID_Invalid;
    __block NSInteger trackSegmentIndex = NSNotFound;
    
    [compositionIDs enumerateKeysAndObjectsUsingBlock:^(NSNumber * _Nonnull trackIDNumber, NSArray<NSUUID *> * _Nonnull compositionIDArray, BOOL * _Nonnull stop_1) {
        [compositionIDArray enumerateObjectsUsingBlock:^(NSUUID * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop_2) {
            if ([obj isEqual:compositionID]) {
                trackID = trackIDNumber.intValue;
                trackSegmentIndex = idx;
                *stop_1 = YES;
                *stop_2 = YES;
            }
        }];
    }];
    
    assert(trackID != kCMPersistentTrackID_Invalid);
    assert(trackSegmentIndex != NSNotFound);
    
    NSMutableDictionary<NSNumber *, NSArray<NSUUID *> *> *mutableCompositionIDs = [compositionIDs mutableCopy];
    NSMutableArray<NSUUID *> *mutableCompositionIDArray = [mutableCompositionIDs[@(trackID)] mutableCopy];
    [mutableCompositionIDArray removeObjectAtIndex:trackSegmentIndex];
    mutableCompositionIDs[@(trackID)] = mutableCompositionIDArray;
    [mutableCompositionIDArray release];
    
    NSMutableDictionary<NSUUID *, NSString *> *mutableTrackSegmentNamesByCompositionID = [trackSegmentNamesByCompositionID mutableCopy];
    [mutableTrackSegmentNamesByCompositionID removeObjectForKey:compositionID];
    
    //
    
    AVMutableCompositionTrack * _Nullable compositionTrack = [mutableComposition trackWithTrackID:trackID];
    assert(completionHandler != nil);
    
    NSArray<AVCompositionTrackSegment *> *oldTrackSegments = compositionTrack.segments;
    AVCompositionTrackSegment *trackSegment = oldTrackSegments[trackSegmentIndex];
    [compositionTrack removeTimeRange:trackSegment.timeMapping.target];
    
    SVVideoProject *videoProject = self.queue_videoProject;
    NSManagedObjectContext *managedObjectContext = videoProject.managedObjectContext;
    
    [managedObjectContext performBlock:^{
        NSFetchRequest *fetchRequest;
        if (trackID == self.mainVideoTrackID) {
            SVVideoTrack *videotrack = videoProject.videoTrack;
            int64_t count = videotrack.videoClipsCount;
            
            assert(count == oldTrackSegments.count);
            
            fetchRequest = [SVVideoClip fetchRequest];
        } else if (trackID == self.audioTrackID) {
            SVAudioTrack *audioTrack = videoProject.audioTrack;
            int64_t count = audioTrack.audioClipsCount;
            
            assert(count == oldTrackSegments.count);
            
            fetchRequest = [SVAudioClip fetchRequest];
        } else {
            abort();
        }
        
        fetchRequest.predicate = [NSPredicate predicateWithFormat:@"%K == %@" argumentArray:@[@"compositionID", compositionID]];
        
        NSBatchDeleteRequest *deleteRequest = [[NSBatchDeleteRequest alloc] initWithFetchRequest:fetchRequest];
        deleteRequest.resultType = NSBatchDeleteResultTypeObjectIDs;
        
        NSPersistentStoreCoordinator *persistentStoreCoordinator = managedObjectContext.persistentStoreCoordinator;
        NSError * _Nullable error = nil;
        NSBatchDeleteResult * _Nullable deleteResult = [persistentStoreCoordinator executeRequest:deleteRequest withContext:managedObjectContext error:&error];
        [deleteRequest release];
        
        if (error) {
            completionHandler(nil, nil, nil, error);
            return;
        }
        
        NSArray<NSManagedObjectID *> *deletedObjectIDs = deleteResult.result;
        
        [NSManagedObjectContext mergeChangesFromRemoteContextSave:@{NSDeletedObjectsKey: deletedObjectIDs} intoContexts:@[managedObjectContext]];
        
        [managedObjectContext save:&error];
        
        if (error) {
            completionHandler(nil, nil, nil, error);
            return;
        }
        
        completionHandler(mutableComposition, mutableCompositionIDs, mutableTrackSegmentNamesByCompositionID, nil);
    }];
    
    [mutableCompositionIDs release];
    [mutableTrackSegmentNamesByCompositionID release];
}

- (void)contextQueue_appendClipsToTrackFromClips:(NSOrderedSet<SVClip *> *)clips
                                         trackID:(CMPersistentTrackID)trackID
                                    videoProject:(SVVideoProject *)videoProject
                              mutableComposition:(AVMutableComposition *)mutableComposition
                                  compositionIDs:(NSMutableDictionary<NSNumber *, NSMutableArray<NSUUID *> *> *)compositionIDs
                trackSegmentNamesByCompositionID:(NSMutableDictionary<NSUUID *, NSString *> *)trackSegmentNamesByCompositionID
                                   createFootage:(BOOL)createFootage
                                           index:(NSUInteger)index
                                  parentProgress:(NSProgress *)parentProgress
                               completionHandler:(void (^)(AVMutableComposition * _Nullable mutableComposition, NSMutableDictionary<NSNumber *, NSMutableArray<NSUUID *> *> * _Nullable compositionIDs, NSMutableDictionary<NSUUID *, NSString *> * _Nullable trackSegmentNamesByCompositionID, NSError * _Nullable error))completionHandler __attribute__((objc_direct)) {
    if (clips.count <= index) {
        completionHandler(mutableComposition, compositionIDs, trackSegmentNamesByCompositionID, nil);
        return;
    }
    
    SVClip *clip = clips[index];
    SVFootage *footage = clip.footage;
    NSUInteger clipsCount = clips.count;
    
    NSUUID *compositionID = clip.compositionID;
    assert(compositionID != nil);
    
    trackSegmentNamesByCompositionID[compositionID] = clip.name;
    
    void (^appendCompositionCompletionHandler)(AVMutableComposition * _Nullable mutableComposition, NSError * _Nullable error) = ^(AVMutableComposition * _Nullable mutableComposition, NSError * _Nullable error) {
        [videoProject.managedObjectContext sv_performBlock:^{
            if (error) {
                completionHandler(nil, nil, nil, error);
                return;
            }
            
            NSUInteger nextIndex = index + 1;
            
            NSMutableArray<NSUUID *> *compositionIDArray;
            if (auto _compositionIDArray = compositionIDs[@(trackID)]) {
                compositionIDArray = _compositionIDArray;
            } else {
                compositionIDArray = [NSMutableArray array];
                compositionIDs[@(trackID)] = compositionIDArray;
            }
            
            [compositionIDArray addObject:compositionID];
            
            if (clipsCount <= nextIndex) {
                completionHandler(mutableComposition, compositionIDs, trackSegmentNamesByCompositionID, nil);
                return;
            }
            
            [self contextQueue_appendClipsToTrackFromClips:clips
                                                   trackID:trackID
                                              videoProject:videoProject
                                        mutableComposition:mutableComposition
                                            compositionIDs:compositionIDs
                          trackSegmentNamesByCompositionID:trackSegmentNamesByCompositionID
                                             createFootage:createFootage
                                                     index:nextIndex
                                            parentProgress:parentProgress
                                         completionHandler:completionHandler];
        }];
    };
    
    if ([footage.entity.name isEqualToString:@"PHAssetFootage"]) {
        auto phAssetFootage = static_cast<SVPHAssetFootage *>(footage);
        NSString *assetIdentifier = phAssetFootage.assetIdentifier;
        
        PHVideoRequestOptions *options = [PHVideoRequestOptions new];
        options.networkAccessAllowed = YES;
        options.deliveryMode = PHVideoRequestOptionsDeliveryModeHighQualityFormat;
        
        NSProgress *progress = [PHImageManager.defaultManager sv_requestAVAssetsForAssetIdentifiers:@[assetIdentifier] options:options partialResultHandler:^(NSString * _Nullable assetIdentifier, AVAsset * _Nullable avAsset, AVAudioMix * _Nullable avAuioMix, NSDictionary * _Nullable info, PHAsset * _Nonnull asset, BOOL * _Nonnull stop, BOOL isEnd) {
            if (static_cast<NSNumber *>(info[PHImageCancelledKey]).boolValue) {
                *stop = YES;
                appendCompositionCompletionHandler(nil, [NSError errorWithDomain:SurfVideoErrorDomain code:SurfVideoUserCancelledError userInfo:nil]);
                return;
            }
            
            if (auto error = static_cast<NSError *>(info[PHImageErrorKey])) {
                *stop = YES;
                appendCompositionCompletionHandler(nil, error);
                return;
            }
            
            if (isEnd) {
                NSError * _Nullable _error = nil;
                
                AVMutableComposition *resultMutableComposition = [self appendClipsToTrackFromAVAssets:@[avAsset] trackID:trackID mutableComposition:mutableComposition error:&_error];
                
                if (_error != nil) {
                    appendCompositionCompletionHandler(nil, _error);
                    return;
                }
                
                appendCompositionCompletionHandler(resultMutableComposition, nil);
            }
        }];
        
        [options release];
        [parentProgress addChild:progress withPendingUnitCount:1];
    } else if ([footage.entity.name isEqualToString:@"LocalFileFootage"]) {
        auto localFileFootage = static_cast<SVLocalFileFootage *>(footage);
        NSString *lastPathCompoent = localFileFootage.fileName;
        NSURL *URL = [SVProjectsManager.sharedInstance.localFileFootagesURL URLByAppendingPathComponent:lastPathCompoent];
        
        NSError * _Nullable error = nil;
        
        AVMutableComposition *resultMutableComposition = [self appendClipsToTrackFromURLs:@[URL] trackID:trackID mutableComposition:mutableComposition error:&error];
        parentProgress.completedUnitCount += 1;
        
        if (error != nil) {
            appendCompositionCompletionHandler(nil, error);
        }
        
        appendCompositionCompletionHandler(resultMutableComposition, nil);
    } else {
        abort();
    }
}

- (NSArray<__kindof EditorRenderElement *> *)contextQueue_renderElementsFromVideoProject:(SVVideoProject *)videoProject {
    SVCaptionTrack *captionTrack = videoProject.captionTrack;
    
    auto results = [[NSMutableArray<__kindof EditorRenderElement *> alloc] initWithCapacity:captionTrack.captionsCount];
    
    for (SVCaption *caption in captionTrack.captions) {
        if (caption.isDeleted) continue;
        if (caption.managedObjectContext == nil) continue;
        
        EditorRenderCaption *rendererCaption = [[EditorRenderCaption alloc] initWithAttributedString:caption.attributedString
                                                                                           startTime:caption.startTimeValue.CMTimeValue
                                                                                             endTime:caption.endTimeValue.CMTimeValue
                                                                                           captionID:caption.captionID];
        
        [results addObject:rendererCaption];
        
        [rendererCaption release];
    }
    
    return [results autorelease];
}

- (void)contextQueue_videoCompositionAndRenderElementsFromComposition:(AVComposition *)composition
                                                         videoProject:(SVVideoProject *)videoProject
                                                    completionHandler:(void (^)(AVVideoComposition * _Nullable videoComposition, NSArray<__kindof EditorRenderElement *> * _Nullable renderElements, NSError * _Nullable error))completionHandler {
    NSArray<__kindof EditorRenderElement *> *elements = [self contextQueue_renderElementsFromVideoProject:videoProject];
    
    [EditorRenderer videoCompositionWithComposition:composition elements:elements completionHandler:^(AVVideoComposition * _Nullable videoComposition, NSError * _Nullable error) {
        if (error) {
            if (completionHandler) {
                completionHandler(nil, nil, error);
                return;
            }
        }
        
        if (completionHandler) {
            completionHandler(videoComposition, elements, nil);
        }
    }];
}

- (void)contextQueue_finalizeWithVideoProject:(SVVideoProject *)videoProject
                                  composition:(AVComposition *)composition
                               compositionIDs:(NSDictionary<NSNumber *, NSArray<NSUUID *> *> *)compositionIDs
             trackSegmentNamesByCompositionID:(NSDictionary<NSUUID *, NSString *> *)trackSegmentNamesByCompositionID
                               renderElements:(NSArray<__kindof EditorRenderElement *> *)renderElements
                            completionHandler:(EditorServiceCompletionHandler)completionHandler {
    [EditorRenderer videoCompositionWithComposition:composition elements:renderElements completionHandler:^(AVVideoComposition * _Nullable videoComposition, NSError * _Nullable error) {
        if (error) {
            completionHandler(nil, nil, nil, nil, nil, error);
            return;
        }
        
        AVAssetImageGenerator *assetImageGenerator = [[AVAssetImageGenerator alloc] initWithAsset:composition];
        assetImageGenerator.videoComposition = videoComposition;
        //        assetImageGenerator.appliesPreferredTrackTransform = YES;
        assetImageGenerator.apertureMode = AVAssetImageGeneratorApertureModeCleanAperture;
        //        assetImageGenerator.requestedTimeToleranceBefore = kCMTimeZero;
        //        assetImageGenerator.requestedTimeToleranceAfter = kCMTimeZero;
        assetImageGenerator.maximumSize = composition.naturalSize;
        
        [assetImageGenerator generateCGImageAsynchronouslyForTime:kCMTimeZero completionHandler:^(CGImageRef  _Nullable image, CMTime actualTime, NSError * _Nullable error) {
            if (error) {
                completionHandler(nil, nil, nil, nil, nil, error);
                return;
            }
            
            NSData *thumbnailImageTIFFData = [ImageUtils TIFFDataFromCIImage:[CIImage imageWithCGImage:image]];
            
            [videoProject.managedObjectContext performBlock:^{
                videoProject.thumbnailImageTIFFData = thumbnailImageTIFFData;
                NSError * _Nullable error = nil;
                [videoProject.managedObjectContext save:&error];
                
                if (error) {
                    completionHandler(nil, nil, nil, nil, nil, error);
                    return;
                }
                
                dispatch_async(self.queue_2, ^{
                    self.queue_videoProject = videoProject;
                    self.queue_composition = composition;
                    self.queue_videoComposition = videoComposition;
                    self.queue_renderElements = renderElements;
                    self.queue_trackSegmentNamesByCompositionID = trackSegmentNamesByCompositionID;
                    self.queue_compositionIDs = compositionIDs;
                    
                    [self queue_postCompositionDidChangeNotification];
                    
                    if (completionHandler) {
                        completionHandler(self.queue_composition, self.queue_videoComposition, self.queue_renderElements, self.queue_trackSegmentNamesByCompositionID, self.queue_compositionIDs, nil);
                    }
                });
            }];
        }];
        
        [assetImageGenerator release];
    }];
}

- (void)queue_postCompositionDidChangeNotification {
    [NSNotificationCenter.defaultCenter postNotificationName:EditorServiceCompositionDidChangeNotification
                                                      object:self
                                                    userInfo:@{
        EditorServiceCompositionKey: self.queue_composition,
        EditorServiceVideoCompositionKey: self.queue_videoComposition,
        EditorServiceCompositionIDsKey: self.queue_compositionIDs,
        EditorServiceRenderElementsKey: self.queue_renderElements,
        EditorServiceTrackSegmentNamesByCompositionIDKey: self.queue_trackSegmentNamesByCompositionID
    }];
}

- (NSProgress *)exportToURLWithQuality:(EditorServiceExportQuality)quality completionHandler:(void (^)(NSURL * _Nullable, NSError * _Nullable))completionHandler {
    NSProgress *progress = [NSProgress progressWithTotalUnitCount:1000000UL];
    
    dispatch_async(self.queue_1, ^{
        AVComposition *composition = self.queue_composition;
        assert(composition.isExportable);
        
        NSString *presetName;
        CGSize renderSize;
        switch (quality) {
            case EditorServiceExportQualityLow:
                presetName = AVAssetExportPresetLowQuality;
                renderSize = CGSizeMake(1280.f, 720.f);
                break;
            case EditorServiceExportQualityMedium:
                presetName = AVAssetExportPresetMediumQuality;
                renderSize = CGSizeMake(1920.f, 1080.f);
                break;
            case EditorServiceExportQualityHigh:
                presetName = AVAssetExportPresetHighestQuality;
                renderSize = CGSizeMake(3840.f, 2160.f);
                break;
            default:
                presetName = AVAssetExportPresetMediumQuality;
                renderSize = composition.naturalSize;
                break;
        }
        
        AVAssetExportSession *assetExportSession = [[AVAssetExportSession alloc] initWithAsset:composition presetName:presetName];
        
        AVMutableVideoComposition *videoComposition = [self.queue_videoComposition mutableCopy];
        videoComposition.renderSize = composition.naturalSize;
        assetExportSession.videoComposition = videoComposition;
        [videoComposition release];
        
        assetExportSession.timeRange = [composition trackWithTrackID:self.mainVideoTrackID].timeRange;
        assetExportSession.shouldOptimizeForNetworkUse = YES;
        
        assetExportSession.outputFileType = AVFileTypeQuickTimeMovie;
        NSURL *outputURL = [NSFileManager.defaultManager.temporaryDirectory URLByAppendingPathComponent:[NSUUID UUID].UUIDString conformingToType:UTTypeQuickTimeMovie];
        assetExportSession.outputURL = outputURL;
        
        NSLog(@"%@", [assetExportSession.outputURL path]);
        
        __weak NSProgress *weakProgress = progress;
        
        NSTimer *timer = [NSTimer timerWithTimeInterval:0.5f repeats:YES block:^(NSTimer * _Nonnull timer) {
            float progress = assetExportSession.progress;
            weakProgress.completedUnitCount = progress * 1000000UL;
        }];
        
        [SVRunLoop.globalTimerRunLoop runBlock:^{
            [NSRunLoop.currentRunLoop addTimer:timer forMode:NSDefaultRunLoopMode];
        }];
        
        KeyValueObservation *statusObservation = [assetExportSession observeValueForKeyPath:@"status" options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew changeHandler:^(AVAssetExportSession *object, NSDictionary * _Nonnull changes) {
            AVAssetExportSessionStatus status;
            if (auto newValue = static_cast<NSNumber *>(changes[NSKeyValueChangeNewKey])) {
                status = static_cast<AVAssetExportSessionStatus>(newValue.integerValue);
            } else {
                status = object.status;
            }
            
            switch (status) {
                case AVAssetExportSessionStatusCompleted:
                    [timer invalidate];
                    
                    if (auto progress = weakProgress) {
                        progress.completedUnitCount = progress.totalUnitCount;
                    }
                    
                    completionHandler(outputURL, nil);
                    break;
                case AVAssetExportSessionStatusFailed:
                    [timer invalidate];
                    completionHandler(nil, object.error);
                    break;
                case AVAssetExportSessionStatusCancelled:
                    [progress cancel];
                    [timer invalidate];
                    completionHandler(nil, [NSError errorWithDomain:SurfVideoErrorDomain code:SurfVideoUserCancelledError userInfo:nil]);
                    break;
                default:
                    break;
            }
        }];
        
        [progress setUserInfoObject:statusObservation forKey:@"statusObservation"];
        
        progress.cancellationHandler = ^{
            if (assetExportSession.status != AVAssetExportSessionStatusCancelled) {
                [assetExportSession cancelExport];
                [timer invalidate];
            }
        };
        
        [assetExportSession exportAsynchronouslyWithCompletionHandler:^{
            
        }];
        
        [assetExportSession release];
    });
    
    return progress;
}

- (NSDictionary<NSNumber *,NSArray<NSUUID *> *> *)appendingCompositionIDArray:(NSArray<NSUUID *> *)addingComposittionIDArray trackID:(CMPersistentTrackID)trackID intoCompositionIDs:(NSDictionary<NSNumber *,NSArray<NSUUID *> *> *)compositionIDs {
    if (addingComposittionIDArray.count == 0) return compositionIDs;
    
    NSMutableDictionary<NSNumber *, NSArray<NSUUID *> *> *mutableCompositionIDs = [compositionIDs mutableCopy];
    
    NSMutableArray<NSUUID *> *compositionIDArray;
    if (id _compositionIDArray = [mutableCompositionIDs[@(trackID)] mutableCopy]) {
        compositionIDArray = [_compositionIDArray autorelease];
    } else {
        compositionIDArray = [[[NSMutableArray alloc] initWithCapacity:addingComposittionIDArray.count] autorelease];
    }
    
    [compositionIDArray addObjectsFromArray:addingComposittionIDArray];
    
    mutableCompositionIDs[@(trackID)] = compositionIDArray;
    
    return [mutableCompositionIDs autorelease];
}

- (NSDictionary<NSNumber *,NSArray<NSUUID *> *> *)deletingCompositionIDArray:(NSArray<NSUUID *> *)deletingComposittionIDArray fromCompositionIDs:(NSDictionary<NSNumber *,NSArray<NSUUID *> *> *)compositionIDs {
    if (deletingComposittionIDArray.count == 0) return compositionIDs;
    
    NSMutableDictionary<NSNumber *, NSArray<NSUUID *> *> *mutableCompositionIDs = [compositionIDs mutableCopy];
    
    [compositionIDs enumerateKeysAndObjectsUsingBlock:^(NSNumber * _Nonnull trackIDNumber, NSArray<NSUUID *> * _Nonnull compositionIDArray, BOOL * _Nonnull stop) {
        NSMutableArray<NSUUID *> *mutableCompositionIDArray = [compositionIDArray mutableCopy];
        
        [mutableCompositionIDArray removeObjectsInArray:deletingComposittionIDArray];
        
        mutableCompositionIDs[trackIDNumber] = mutableCompositionIDArray;
        [mutableCompositionIDArray release];
    }];
    
    return [mutableCompositionIDs autorelease];
}

- (void)appendClipsFromURLs:(NSArray<NSURL *> *)urls intoTrackID:(CMPersistentTrackID)trackID progressHandler:(void (^)(NSProgress * _Nonnull))progressHandler completionHandler:(EditorServiceCompletionHandler)completionHandler {
    dispatch_async(self.queue_1, ^{
        dispatch_suspend(self.queue_1);
        
        AVMutableComposition *mutableComposition = [self.queue_composition mutableCopy];
        SVVideoProject *videoProject = self.queue_videoProject;
        NSDictionary<NSNumber *, NSArray<NSUUID *> *> *compositionIDs = self.queue_compositionIDs;
        NSArray<__kindof EditorRenderElement *> *renderElements = self.queue_renderElements;
        NSDictionary<NSUUID *, NSString *> *trackSegmentNamesByCompositionID = self.queue_trackSegmentNamesByCompositionID;
        NSManagedObjectContext *managedObjectContext = videoProject.managedObjectContext;
        
        [managedObjectContext performBlock:^{
            NSError * _Nullable error = nil;
            NSDictionary<NSString *, id> *results = [self contextQueue_createSVClipsFromSourceURLs:urls videoProject:videoProject trackID:trackID error:&error];
            
            if (error != nil) {
                completionHandler(nil, nil, nil, nil, nil, error);
                dispatch_resume(self.queue_1);
                return;
            }
            
            NSArray<NSUUID *> *createdCompositionIDArray = results[@"createdCompositionIDArray"];
            NSArray<NSURL *> *footageURLArray = results[@"footageURLArray"];
            NSDictionary<NSUUID *, NSString *> *titlesByCompositionID = results[@"titlesByCompositionID"];
            
            AVMutableComposition *resultMutableComposition = [self appendClipsToTrackFromURLs:footageURLArray
                                                                                      trackID:trackID
                                                                           mutableComposition:mutableComposition
                                                                                        error:&error];
            
            if (error != nil) {
                completionHandler(nil, nil, nil, nil, nil, error);
                dispatch_resume(self.queue_1);
                return;
            }
            
            NSDictionary<NSNumber *,NSArray<NSUUID *> *> *newCompositionIDs = [self appendingCompositionIDArray:createdCompositionIDArray trackID:trackID intoCompositionIDs:compositionIDs];
            NSMutableDictionary<NSUUID *, NSString *> *newTrackSegmentNamesByCompositionID = [trackSegmentNamesByCompositionID mutableCopy];
            
            [newTrackSegmentNamesByCompositionID addEntriesFromDictionary:titlesByCompositionID];
            
            [self contextQueue_finalizeWithVideoProject:videoProject
                                            composition:resultMutableComposition
                                         compositionIDs:newCompositionIDs
                       trackSegmentNamesByCompositionID:newTrackSegmentNamesByCompositionID
                                         renderElements:renderElements
                                      completionHandler:EditorServiceCompletionHandlerBlock {
                completionHandler(composition, videoComposition, renderElements, trackSegmentNamesByCompositionID, compositionIDs, error);
                dispatch_resume(self.queue_1);
            }];
            
            [newTrackSegmentNamesByCompositionID release];
        }];
        
        [mutableComposition release];
    });
}

- (void)removeClipWithCompositionID:(NSUUID *)compositionID completionHandler:(void (^)(AVComposition * _Nullable, AVVideoComposition * _Nullable, NSArray<__kindof EditorRenderElement *> * _Nullable, NSDictionary<NSUUID *,NSString *> * _Nullable, NSDictionary<NSNumber *,NSArray<NSUUID *> *> * _Nullable, NSError * _Nullable))completionHandler {
    dispatch_async(self.queue_1, ^{
        dispatch_suspend(self.queue_1);
        
        AVMutableComposition *mutableComposition = [self.queue_composition mutableCopy];
        SVVideoProject *videoProject = self.queue_videoProject;
        NSManagedObjectContext *managedObjectContext = self.queue_videoProject.managedObjectContext;
        NSDictionary<NSNumber *, NSArray<NSUUID *> *> *compositionIDs = self.queue_compositionIDs;
        NSArray<__kindof EditorRenderElement *> *renderElements = self.queue_renderElements;
        NSDictionary<NSUUID *, NSString *> *trackSegmentNamesByCompositionID = self.queue_trackSegmentNamesByCompositionID;
        
        [self queue_removeTrackSegmentWithCompositionID:compositionID
                                     mutableComposition:mutableComposition
                                         compositionIDs:compositionIDs
                       trackSegmentNamesByCompositionID:trackSegmentNamesByCompositionID
                                      completionHandler:^(AVMutableComposition * _Nullable mutableComposition, NSDictionary<NSNumber *,NSArray<NSUUID *> *> * _Nullable compositionIDs, NSDictionary<NSUUID *, NSString *> * _Nullable trackSegmentNamesByCompositionID, NSError * _Nullable error) {
            if (error) {
                completionHandler(nil, nil, nil, nil, nil, error);
                dispatch_resume(self.queue_1);
                return;
            }
            
            [managedObjectContext performBlock:^{
                [self contextQueue_finalizeWithVideoProject:videoProject 
                                                composition:mutableComposition 
                                             compositionIDs:compositionIDs
                           trackSegmentNamesByCompositionID:trackSegmentNamesByCompositionID
                                             renderElements:renderElements
                                          completionHandler:EditorServiceCompletionHandlerBlock {
                    completionHandler(composition, videoComposition, renderElements, trackSegmentNamesByCompositionID, compositionIDs, error);
                    dispatch_resume(self.queue_1);
                }];
            }];
        }];
        
        [mutableComposition release];
    });
}

- (NSArray<NSString *> *)assetIdentifiersFromPickerResults:(NSArray<PHPickerResult *> *)pickerResults {
    NSMutableArray *assetIdentifiers = [[NSMutableArray alloc] initWithCapacity:pickerResults.count];
    
    for (PHPickerResult *pickerResult in pickerResults) {
        [assetIdentifiers addObject:pickerResult.assetIdentifier];
    }
    
    return [assetIdentifiers autorelease];
}

- (NSDictionary<AVAsset *,NSString *> *)titlesFromAVAssets:(NSArray<AVAsset *> *)avAssets {
    NSMutableDictionary<AVAsset *, NSString *> *result = [NSMutableDictionary dictionary];
    
    for (AVAsset *avAsset in avAssets) {
        NSString * _Nullable title = nil;
        for (AVMetadataItem *metadataItem in avAsset.metadata) {
            if ([metadataItem.commonKey isEqualToString:AVMetadataCommonKeyTitle]) {
                title = static_cast<NSString *>(metadataItem.value);
                break;
            }
        }
        
        if (title != nil) {
            result[avAsset] = title;
        }
    }
    
    return result;
}

- (NSDictionary<NSString *,NSString *> *)titlesByAssetIdentifierWithAVAssetsByAssetIdentifier:(NSDictionary<NSString *,AVAsset *> *)avAssetsByAssetIdentifier titlesByAVAsset:(NSDictionary<AVAsset *,NSString *> *)titlesByAVAsset {
    if ((avAssetsByAssetIdentifier.count == 0) || (titlesByAVAsset.count == 0)) {
        return [NSDictionary dictionary];
    }
    
    NSMutableDictionary<NSString *, NSString *> *titlesByAssetIdentifier = [[NSMutableDictionary alloc] initWithCapacity:titlesByAVAsset.count];
    
    [titlesByAVAsset enumerateKeysAndObjectsUsingBlock:^(AVAsset * _Nonnull avAsset_1, NSString * _Nonnull title, BOOL * _Nonnull stop_1) {
        [avAssetsByAssetIdentifier enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull assetIdentifier, AVAsset * _Nonnull avAsset_2, BOOL * _Nonnull stop_2) {
            if ([avAsset_1 isEqual:avAsset_2]) {
                titlesByAssetIdentifier[assetIdentifier] = title;
                *stop_2 = YES;
            }
        }];
    }];
    
    return [titlesByAssetIdentifier autorelease];
}

@end
