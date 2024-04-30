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
#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>
#include <sys/clonefile.h>

@implementation EditorService (Private)

- (dispatch_queue_t)queue {
    return _queue;
}

- (SVVideoProject *)queue_videoProject {
    dispatch_assert_queue_debug(_queue);
    
    return _queue_videoProject;
}

- (void)queue_setVideoProject:(SVVideoProject *)queue_videoProject {
    dispatch_assert_queue_debug(_queue);
    
    [_queue_videoProject release];
    _queue_videoProject = [queue_videoProject retain];
}

- (NSSet<NSUserActivity *> *)userActivities {
    return _userActivities;
}

- (AVComposition *)queue_composition {
    dispatch_assert_queue_debug(_queue);
    
    return _queue_composition;
}

- (void)queue_setComposition:(AVComposition *)queue_composition {
    dispatch_assert_queue_debug(_queue);
    
    [_queue_composition release];
    _queue_composition = [queue_composition copy];
}

- (AVVideoComposition *)queue_videoComposition {
    dispatch_assert_queue_debug(_queue);
    
    return _queue_videoComposition;
}

- (void)queue_setVideoComposition:(AVVideoComposition *)queue_videoComposition {
    dispatch_assert_queue_debug(_queue);
    
    [_queue_videoComposition release];
    _queue_videoComposition = [queue_videoComposition copy];
}

- (NSArray<__kindof EditorRenderElement *> *)queue_renderElements {
    dispatch_assert_queue_debug(_queue);
    
    return _queue_renderElements;
}

- (void)queue_setRenderElements:(NSArray<__kindof EditorRenderElement *> *)queue_renderElements {
    dispatch_assert_queue_debug(_queue);
    
    [_queue_renderElements release];
    _queue_renderElements = [queue_renderElements copy];
}

- (NSDictionary<NSNumber *, NSDictionary<NSNumber *, NSString *> *> *)queue_trackSegmentNames {
    dispatch_assert_queue_debug(_queue);
    
    return _queue_trackSegmentNames;
}

- (void)queue_setTrackSegmentNames:(NSDictionary<NSNumber *, NSDictionary<NSNumber *, NSString *> *> *)queue_trackSegmentNames {
    dispatch_assert_queue_debug(_queue);
    
    [_queue_trackSegmentNames release];
    _queue_trackSegmentNames = [queue_trackSegmentNames copy];
}

- (NSDictionary<NSNumber *, NSArray<NSUUID *> *> *)queue_compositionIDs {
    dispatch_assert_queue_debug(_queue);
    
    return _queue_compositionIDs;
}

- (void)queue_setCompositionIDs:(NSDictionary<NSNumber *, NSArray<NSUUID *> *> *)queue_compositionIDs {
    dispatch_assert_queue_debug(_queue);
    
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
            auto videoProject = static_cast<SVVideoProject *>([managedObjectContext objectWithID:objectID]);
            
            dispatch_async(self.queue, ^{
                self.queue_videoProject = videoProject;
                completionHandler(videoProject, nil);
            });
        }];
    }];
}

- (void)queue_mutableCompositionFromVideoProject:(SVVideoProject *)videoProject progressHandler:(void (^)(NSProgress *progress))progressHandler completionHandler:(void (^)(AVMutableComposition * _Nullable mutableComposition, NSDictionary<NSNumber *, NSArray<NSUUID *> *> * _Nullable compositionIDs,  NSError * _Nullable error))completionHandler {
    NSManagedObjectContext * _Nullable managedObjectContext = videoProject.managedObjectContext;
    if (!managedObjectContext) {
        completionHandler(nil, nil, [NSError errorWithDomain:SurfVideoErrorDomain code:SurfVideoNoManagedObjectContextError userInfo:nil]);
        return;
    }
    
    AVMutableComposition *mutableComposition = [AVMutableComposition composition];
    mutableComposition.naturalSize = CGSizeMake(1280.f, 720.f);
    [mutableComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:self.mainVideoTrackID];
    [mutableComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:self.audioTrackID];
    
    NSMutableDictionary<NSNumber *, NSMutableArray<NSUUID *> *> *compositionIDs = [NSMutableDictionary dictionary];
    
    [managedObjectContext performBlock:^{
        NSOrderedSet<SVVideoClip *> *videoClips = videoProject.videoTrack.videoClips;
        NSOrderedSet<SVAudioClip *> *audioClips = videoProject.audioTrack.audioClips;
        
        NSProgress *progress = [NSProgress progressWithTotalUnitCount:videoClips.count + audioClips.count];
        progressHandler(progress);
        
        [self contextQueue_appendClipsToTrackFromClips:videoClips
                                               trackID:self.mainVideoTrackID 
                                  managedObjectContext:managedObjectContext
                                    mutableComposition:mutableComposition
                                        compositionIDs:compositionIDs
                                         createFootage:NO 
                                                 index:0
                                        parentProgress:progress
                                     completionHandler:^(AVMutableComposition * _Nullable mutableComposition, NSMutableDictionary<NSNumber *, NSMutableArray<NSUUID *> *> * _Nullable compositionIDs, NSError * _Nullable error) {
            if (error) {
                completionHandler(nil, nil, error);
                return;
            }
            
            [managedObjectContext performBlock:^{
                [self contextQueue_appendClipsToTrackFromClips:audioClips
                                                       trackID:self.audioTrackID
                                          managedObjectContext:managedObjectContext
                                            mutableComposition:mutableComposition
                                                compositionIDs:compositionIDs
                                                 createFootage:NO
                                                         index:0 parentProgress:progress
                                             completionHandler:^(AVMutableComposition * _Nullable mutableComposition, NSMutableDictionary<NSNumber *, NSMutableArray<NSUUID *> *> * _Nullable compositionIDs, NSError * _Nullable error) {
                    if (error) {
                        completionHandler(nil, nil, error);
                        return;
                    }
                    
                    completionHandler(mutableComposition, compositionIDs, error);
                }];
            }];
        }];
    }];
}

- (void)queue_appendClipsToTrackFromPickerResults:(NSArray<PHPickerResult *> *)pickerResults trackID:(CMPersistentTrackID)trackID mutableComposition:(AVMutableComposition *)mutableComposition createFootage:(BOOL)createFootage progressHandler:(void (^)(NSProgress * _Nonnull))progressHandler completionHandler:(void (^)(AVMutableComposition * _Nullable mutableComposition, NSDictionary<NSString *, NSUUID *> *createdCompositionIDs, NSError * _Nullable error))completionHandler {
    auto assetIdentifiers = [NSMutableArray<NSString *> new];
    
    for (PHPickerResult *result in pickerResults) {
        NSString *assetIdentifier = result.assetIdentifier;
        
        [assetIdentifiers addObject:assetIdentifier];
    }
    
    [self queue_appendClipsToTrackFromAssetIdentifiers:assetIdentifiers
                                               trackID:trackID
                                              mutableComposition:mutableComposition
                                                   createFootage:createFootage
                                                 progressHandler:progressHandler
                                     completionHandler:completionHandler];
    
    [assetIdentifiers release];
}

- (void)queue_appendClipsToTrackFromAssetIdentifiers:(NSArray<NSString *> *)assetIdentifiers trackID:(CMPersistentTrackID)trackID mutableComposition:(AVMutableComposition *)mutableComposition createFootage:(BOOL)createFootage progressHandler:(void (^)(NSProgress * _Nonnull))progressHandler completionHandler:(void (^)(AVMutableComposition * _Nullable mutableComposition, NSDictionary<NSString *, NSUUID *> *createdCompositionIDs, NSError * _Nullable error))completionHandler {
    SVVideoProject *videoProject = self.queue_videoProject;
    NSManagedObjectContext *managedObjectContext = videoProject.managedObjectContext;
    NSUInteger assetIdentifiersCount = assetIdentifiers.count;
    PHImageManager *imageManager = PHImageManager.defaultManager;
    PHVideoRequestOptions *videoRequestOptions = [PHVideoRequestOptions new];
    videoRequestOptions.deliveryMode = PHVideoRequestOptionsDeliveryModeHighQualityFormat;
    videoRequestOptions.networkAccessAllowed = YES;
    
    NSMutableArray<AVAsset *> *avAssets = [[NSMutableArray<AVAsset *> alloc] initWithCapacity:assetIdentifiersCount];
    
    // Loading PHAssets + Loading AVAssets + Core Data Transaction
    int64_t progressTotalUnitCount;
    if (createFootage) {
        progressTotalUnitCount = assetIdentifiersCount * 2 + 1;
    } else {
        progressTotalUnitCount = assetIdentifiersCount * 2;
    }
    
    NSProgress *parentProgress = [NSProgress progressWithTotalUnitCount:progressTotalUnitCount];
    progressHandler(parentProgress);
    
    NSProgress *progress = [imageManager sv_requestAVAssetsForAssetIdentifiers:assetIdentifiers options:videoRequestOptions partialResultHandler:^(AVAsset * _Nullable avAsset, AVAudioMix * _Nullable avAuioMix, NSDictionary * _Nullable info, PHAsset * _Nonnull asset, BOOL *stop, BOOL isEnd) {
        if (static_cast<NSNumber *>(info[PHImageCancelledKey]).boolValue) {
            *stop = YES;
            completionHandler(nil, nil, [NSError errorWithDomain:SurfVideoErrorDomain code:SurfVideoUserCancelledError userInfo:nil]);
            return;
        }
        
        if (auto error = static_cast<NSError *>(info[PHImageErrorKey])) {
            *stop = YES;
            completionHandler(nil, nil, error);
            return;
        }
        
        [avAssets addObject:avAsset];
        
        if (isEnd) {
            dispatch_async(self.queue, ^{
                NSError * _Nullable error = nil;
                
                [self appendClipsToTrackFromAVAssets:avAssets trackID:trackID progress:parentProgress progressUnit:1 mutableComposition:mutableComposition error:&error];
                
                if (error) {
                    completionHandler(nil, nil, error);
                    return;
                }
                
                if (createFootage) {
                    [managedObjectContext performBlock:^{
                        NSError * _Nullable error = nil;
                        
                        NSDictionary<NSString *, SVPHAssetFootage *> *phAssetFootages = [SVProjectsManager.sharedInstance contextQueue_phAssetFootagesFromAssetIdentifiers:assetIdentifiers createIfNeededWithoutSaving:YES managedObjectContext:managedObjectContext error:&error];
                        
                        NSMutableDictionary<NSString *, NSUUID *> *createdCompositionIDs = [[[NSMutableDictionary alloc] initWithCapacity:assetIdentifiersCount] autorelease];
                        
                        if (error) {
                            completionHandler(nil, nil, error);
                            return;
                        }
                        
                        //
                        
                        if (trackID == self.mainVideoTrackID) {
                            SVVideoTrack *mainVideoTrack = videoProject.videoTrack;
                            
                            for (NSString *assetIdentifier in assetIdentifiers) {
                                SVPHAssetFootage *phAssetFootage = phAssetFootages[assetIdentifier];
                                
                                SVVideoClip *videoClip = [[SVVideoClip alloc] initWithContext:managedObjectContext];
                                NSUUID *compositionID = [NSUUID UUID];
                                
                                videoClip.footage = phAssetFootage;
                                videoClip.compositionID = compositionID;
                                
                                [mainVideoTrack addVideoClipsObject:videoClip];
                                [videoClip release];
                                
                                createdCompositionIDs[assetIdentifier] = compositionID;
                            }
                        } else if (trackID == self.audioTrackID) {
                            SVAudioTrack *audioTrack = videoProject.audioTrack;
                            
                            for (NSString *assetIdentifier in assetIdentifiers) {
                                SVPHAssetFootage *phAssetFootage = phAssetFootages[assetIdentifier];
                                
                                SVAudioClip *audioClip = [[SVAudioClip alloc] initWithContext:managedObjectContext];
                                NSUUID *compositionID = [NSUUID UUID];
                                
                                audioClip.footage = phAssetFootage;
                                audioClip.compositionID = compositionID;
                                
                                [audioTrack addAudioClipsObject:audioClip];
                                [audioClip release];
                                
                                createdCompositionIDs[assetIdentifier] = compositionID;
                            }
                        }
                        
                        [managedObjectContext save:&error];
                        
                        if (error) {
                            completionHandler(nil,  nil,error);
                            return;
                        }
                        
                        parentProgress.completedUnitCount += 1;
                        completionHandler(mutableComposition, createdCompositionIDs, nil);
                    }];
                } else {
                    completionHandler(mutableComposition, nil, nil);
                }
            });
        }
    }];
    
    [parentProgress addChild:progress withPendingUnitCount:assetIdentifiersCount];
    
    [videoRequestOptions release];
    [avAssets release];
}

- (void)queue_appendClipsToTrackFromURLs:(NSArray<NSURL *> *)sourceURLs trackID:(CMPersistentTrackID)trackID mutableComposition:(AVMutableComposition *)mutableComposition createFootage:(BOOL)createFootage progressHandler:(void (^)(NSProgress * _Nonnull))progressHandler completionHandler:(void (^)(AVMutableComposition * _Nullable mutableComposition, NSDictionary<NSURL *, NSUUID *> * _Nullable createdCompositionIDs, NSError * _Nullable error))completionHandler {
    NSUInteger sourceURLsCount = sourceURLs.count;
    
    // AVAssets Creation = 1, Core Data Transaction = 1
    int64_t progressTotalCount;
    if (createFootage) {
        progressTotalCount = sourceURLsCount + 1;
    } else {
        progressTotalCount = sourceURLsCount + 2;
    }
    
    NSProgress *progress = [NSProgress progressWithTotalUnitCount:progressTotalCount];
    progressHandler(progress);
    
    SVVideoProject *videoProject = self.queue_videoProject;
    NSManagedObjectContext *managedObjectContext = videoProject.managedObjectContext;
    NSMutableArray<AVURLAsset *> *avAssets = [[[NSMutableArray alloc] initWithCapacity:sourceURLsCount] autorelease];
    NSMutableDictionary<NSURL *, NSString *> *namesBySourceURL = [[[NSMutableDictionary alloc] initWithCapacity:sourceURLsCount] autorelease];
    NSMutableDictionary<NSURL *, NSURL *> *assetURLBySourceURL = [[[NSMutableDictionary alloc] initWithCapacity:sourceURLsCount] autorelease];
    
    //
    
    for (NSURL *sourceURL in sourceURLs) {
        NSURL *assetURL;
        if (createFootage) {
            NSError * _Nullable error = nil;
            assetURL = [self copyToLocalFileFootageFromURL:sourceURL error:&error];
            
            if (error) {
                completionHandler(nil, nil, error);
                return;
            }
        } else {
            assetURL = sourceURL;
        }
        
        assetURLBySourceURL[sourceURL] = assetURL;
        AVURLAsset *avAsset = [AVURLAsset assetWithURL:assetURL];
        
        NSString * _Nullable title = nil;
        for (AVMetadataItem *metadataItem in avAsset.metadata) {
            if ([metadataItem.commonKey isEqualToString:AVMetadataCommonKeyTitle]) {
                title = static_cast<NSString *>(metadataItem.value);
                break;
            }
        }
        
        if (title == nil) {
            title = [sourceURL URLByDeletingPathExtension].lastPathComponent;
        }
        
        [avAssets addObject:avAsset];
        
        if (title != nil) {
            namesBySourceURL[sourceURL] = title;
        }
    }
    
    progress.completedUnitCount += 1;
    
    //
    
    NSError * _Nullable error = nil;
    [self appendClipsToTrackFromAVAssets:avAssets trackID:trackID progress:progress progressUnit:1 mutableComposition:mutableComposition error:&error];
    
    if (error) {
        completionHandler(nil, nil, error);
        return;
    }
    
    if (createFootage) {
        [managedObjectContext performBlock:^{
            NSMutableDictionary<NSURL *, NSUUID *> *createdCompositionIDs = [[[NSMutableDictionary alloc] initWithCapacity:sourceURLsCount] autorelease];
            
            if (trackID == self.mainVideoTrackID) {
                SVVideoTrack *mainVideoTrack = videoProject.videoTrack;
                
                for (NSURL *sourceURL in sourceURLs) {
                    // TODO: 무조건 새로 만들면 안 됨
                    SVLocalFileFootage *localFileFootage = [[SVLocalFileFootage alloc] initWithContext:managedObjectContext];
                    localFileFootage.lastPathComponent = assetURLBySourceURL[sourceURL].lastPathComponent;
                    
                    SVVideoClip *videoClip = [[SVVideoClip alloc] initWithContext:managedObjectContext];
                    NSUUID *compositionID = [NSUUID UUID];
                    
                    videoClip.footage = localFileFootage;
                    videoClip.name = namesBySourceURL[sourceURL];
                    videoClip.compositionID = compositionID;
                    [localFileFootage release];
                    
                    [mainVideoTrack addVideoClipsObject:videoClip];
                    [videoClip release];
                    
                    createdCompositionIDs[sourceURL] = compositionID;
                }
            } else if (trackID == self.audioTrackID) {
                SVAudioTrack *audioTrack = videoProject.audioTrack;
                
                for (NSURL *sourceURL in sourceURLs) {
                    SVLocalFileFootage *localFileFootage = [[SVLocalFileFootage alloc] initWithContext:managedObjectContext];
                    localFileFootage.lastPathComponent = assetURLBySourceURL[sourceURL].lastPathComponent;
                    
                    SVAudioClip *audioClip = [[SVAudioClip alloc] initWithContext:managedObjectContext];
                    NSUUID *compositionID = [NSUUID UUID];
                    
                    audioClip.footage = localFileFootage;
                    audioClip.name = namesBySourceURL[sourceURL];
                    audioClip.compositionID = compositionID;
                    [localFileFootage release];
                    
                    [audioTrack addAudioClipsObject:audioClip];
                    [audioClip release];
                    
                    createdCompositionIDs[sourceURL] = compositionID;
                }
            }
            
            NSError * _Nullable error = nil;
            [managedObjectContext save:&error];
            
            if (error) {
                completionHandler(nil, nil, error);
                return;
            }
            
            progress.completedUnitCount += 1;
            completionHandler(mutableComposition, createdCompositionIDs, nil);
        }];
    } else {
        completionHandler(mutableComposition, nil, nil);
    }
}

- (BOOL)appendClipsToTrackFromAVAssets:(NSArray<AVAsset *> *)avAssets trackID:(CMPersistentTrackID)trackID progress:(NSProgress *)progress progressUnit:(int64_t)progressUnit mutableComposition:(AVMutableComposition *)mutableComposition error:(NSError * _Nullable * _Nullable)error {
    AVMutableCompositionTrack *compositionTrack = [mutableComposition trackWithTrackID:trackID];
    
    if (compositionTrack == nil) {
        if (error) {
            *error = [NSError errorWithDomain:SurfVideoErrorDomain code:SurfVideoNoTrackFoundError userInfo:nil];
        }
        
        return NO;
    }
    
    
    if (trackID == self.mainVideoTrackID) {
        for (AVAsset *avAsset in avAssets) {
            for (AVAssetTrack *assetTrack in avAsset.tracks) {
                if ([assetTrack.mediaType isEqualToString:AVMediaTypeVideo]) {
                    [compositionTrack insertTimeRange:assetTrack.timeRange ofTrack:assetTrack atTime:compositionTrack.timeRange.duration error:error];
                    
                    if (*error) {
                        return NO;
                    }
                }
            }
            
            progress.completedUnitCount += progressUnit;
        }
    } else if (trackID == self.audioTrackID) {
        for (AVAsset *avAsset in avAssets) {
            for (AVAssetTrack *assetTrack in avAsset.tracks) {
                if ([assetTrack.mediaType isEqualToString:AVMediaTypeAudio]) {
                    [compositionTrack insertTimeRange:assetTrack.timeRange ofTrack:assetTrack atTime:compositionTrack.timeRange.duration error:error];
                    
                    if (*error) {
                        return NO;
                    }
                }
            }
            
            progress.completedUnitCount += progressUnit;
        }
    } else {
        if (error) {
            *error = [NSError errorWithDomain:SurfVideoErrorDomain code:SurfVideoUnknownTrackID userInfo:nil];
        }
        return NO;
    }
    
    return YES;
}

- (void)queue_removeTrackSegmentWithCompositionID:(NSUUID *)compositionID mutableComposition:(AVMutableComposition *)mutableComposition compositionIDs:(NSDictionary<NSNumber *,NSArray<NSUUID *> *> *)compositionIDs completionHandler:(void (^)(AVMutableComposition * _Nullable mutableComposition, NSDictionary<NSNumber *, NSArray<NSUUID *> *> * _Nullable compositionIDs, NSError * _Nullable error))completionHandler {
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
            completionHandler(nil, nil, error);
            return;
        }
        
        NSArray<NSManagedObjectID *> *deletedObjectIDs = deleteResult.result;
        
        [NSManagedObjectContext mergeChangesFromRemoteContextSave:@{NSDeletedObjectsKey: deletedObjectIDs} intoContexts:@[managedObjectContext]];
        
        [managedObjectContext save:&error];
        
        if (error) {
            completionHandler(nil, nil, error);
            return;
        }
        
        completionHandler(mutableComposition, mutableCompositionIDs, nil);
    }];
    
    [mutableCompositionIDs release];
}

- (void)contextQueue_appendClipsToTrackFromClips:(NSOrderedSet<SVClip *> *)clips
                                         trackID:(CMPersistentTrackID)trackID 
                            managedObjectContext:(NSManagedObjectContext *)managedObjectContext
                              mutableComposition:(AVMutableComposition *)mutableComposition
                                  compositionIDs:(NSMutableDictionary<NSNumber *, NSMutableArray<NSUUID *> *> *)compositionIDs
                                   createFootage:(BOOL)createFootage 
                                           index:(NSUInteger)index 
                                  parentProgress:(NSProgress *)parentProgress
                               completionHandler:(void (^)(AVMutableComposition * _Nullable mutableComposition, NSMutableDictionary<NSNumber *, NSMutableArray<NSUUID *> *> * _Nullable compositionIDs, NSError * _Nullable error))completionHandler __attribute__((objc_direct)) {
    if (clips.count <= index) {
        completionHandler(mutableComposition, compositionIDs, nil);
        return;
    }
    
    SVClip *clip = clips[index];
    SVFootage *footage = clip.footage;
    NSUInteger clipsCount = clips.count;
    
    NSUUID *compositionID = clip.compositionID;
    assert(compositionID != nil);
    
    void (^appendCompositionCompletionHandler)(AVMutableComposition * _Nullable mutableComposition, NSError * _Nullable error) = ^(AVMutableComposition * _Nullable mutableComposition, NSError * _Nullable error) {
        [managedObjectContext performBlock:^{
            if (error) {
                completionHandler(nil, nil, error);
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
                completionHandler(mutableComposition, compositionIDs, nil);
                return;
            }
            
            [self contextQueue_appendClipsToTrackFromClips:clips
                                                   trackID:trackID
                                      managedObjectContext:managedObjectContext
                                        mutableComposition:mutableComposition
                                            compositionIDs:compositionIDs
                                             createFootage:createFootage
                                                     index:nextIndex
                                            parentProgress:parentProgress
                                         completionHandler:completionHandler];
        }];
    };
    
    if ([footage.entity.name isEqualToString:@"PHAssetFootage"]) {
        auto phAssetFootage = static_cast<SVPHAssetFootage *>(footage);
        NSString *assetIdentifier = phAssetFootage.assetIdentifier;
        
        dispatch_async(self.queue, ^{
            [self queue_appendClipsToTrackFromAssetIdentifiers:@[assetIdentifier]
                                                       trackID:trackID
                                            mutableComposition:mutableComposition
                                                 createFootage:createFootage
                                               progressHandler:^(NSProgress *progress) {
                [parentProgress addChild:progress withPendingUnitCount:1000000LL];
            } 
                                             completionHandler:^(AVMutableComposition * _Nullable mutableComposition, NSDictionary<NSString *,NSUUID *> * _Nullable createdCompositionIDs, NSError * _Nullable error) {
                appendCompositionCompletionHandler(mutableComposition, error);
            }];
        });
    } else if ([footage.entity.name isEqualToString:@"LocalFileFootage"]) {
        auto localFileFootage = static_cast<SVLocalFileFootage *>(footage);
        NSString *lastPathCompoent = localFileFootage.lastPathComponent;
        NSURL *URL = [SVProjectsManager.sharedInstance.localFileFootagesURL URLByAppendingPathComponent:lastPathCompoent];
        
        dispatch_async(self.queue, ^{
            [self queue_appendClipsToTrackFromURLs:@[URL]
                                           trackID:trackID
                                mutableComposition:mutableComposition
                                     createFootage:createFootage
                                   progressHandler:^(NSProgress *progress) {
                [parentProgress addChild:progress withPendingUnitCount:1000000LL];
            } 
                                 completionHandler:^(AVMutableComposition * _Nullable mutableComposition, NSDictionary<NSURL *,NSUUID *> * _Nullable createdCompositionIDs, NSError * _Nullable error) {
                appendCompositionCompletionHandler(mutableComposition, error);
            }];
        });
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

// TODO: 불안정함 Composition ID가 Input이고 Ouput이 names로 해야함.
- (NSDictionary<NSNumber *, NSDictionary<NSNumber *, NSString *> *> *)contextQueue_trackSegmentNamesFromComposition:(AVComposition *)composition videoProject:(SVVideoProject *)videoProject {
    auto trackSegmentNames = [NSMutableDictionary<NSNumber *, NSDictionary<NSNumber *, NSString *> *> new];
    
    if (AVCompositionTrack *mainVideoTrack = [composition trackWithTrackID:self.mainVideoTrackID]) {
        NSUInteger count = mainVideoTrack.segments.count;
        
        if (count > 0) {
            SVVideoTrack *svVideoTrack = videoProject.videoTrack;
//            assert(count == svVideoTrack.videoClipsCount);
            assert(count == svVideoTrack.videoClips.count);
            
            NSMutableDictionary<NSNumber *, NSString *> *results = [NSMutableDictionary new];
            
            [mainVideoTrack.segments enumerateObjectsUsingBlock:^(AVCompositionTrackSegment * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                SVVideoClip *videoClip = svVideoTrack.videoClips[idx];
                
                if (auto name = videoClip.name) {
                    results[@(idx)] = name;
                }
            }];
            
            if (results.count > 0) {
                trackSegmentNames[@(self.mainVideoTrackID)] = results;
            }
            
            [results release];
        }
    }
    
    if (AVCompositionTrack *audioideoTrack = [composition trackWithTrackID:self.audioTrackID]) {
        NSUInteger count = audioideoTrack.segments.count;
        
        if (count > 0) {
            SVAudioTrack *svAudioTrack = videoProject.audioTrack;
//            assert(count == svAudioTrack.audioClipsCount);
            assert(count == svAudioTrack.audioClips.count);
            
            NSMutableDictionary<NSNumber *, NSString *> *results = [NSMutableDictionary new];
            
            [audioideoTrack.segments enumerateObjectsUsingBlock:^(AVCompositionTrackSegment * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                SVAudioClip *audioClip = svAudioTrack.audioClips[idx];
                
                if (auto name = audioClip.name) {
                    results[@(idx)] = name;
                }
            }];
            
            if (results.count > 0) {
                trackSegmentNames[@(self.audioTrackID)] = results;
            }
            
            [results release];
        }
    }
    
    return [trackSegmentNames autorelease];
}

- (void)contextQueue_finalizeWithComposition:(AVComposition *)composition
                              compositionIDs:(NSDictionary<NSNumber *, NSArray<NSUUID *> *> *)compositionIDs
                              renderElements:(NSArray<__kindof EditorRenderElement *> *)renderElements
                                videoProject:(SVVideoProject *)videoProject
                           completionHandler:(EditorServiceCompletionHandler)completionHandler {
    NSDictionary<NSNumber *, NSDictionary<NSNumber *, NSString *> *> *trackSegmentNames = [self contextQueue_trackSegmentNamesFromComposition:composition videoProject:videoProject];
    
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
            
            id imageObject = (id)image;
            
            dispatch_async(self.queue, ^{
                NSData *thumbnailImageTIFFData = [ImageUtils TIFFDataFromCIImage:[CIImage imageWithCGImage:(CGImageRef)imageObject]];
                
                [videoProject.managedObjectContext performBlock:^{
                    videoProject.thumbnailImageTIFFData = thumbnailImageTIFFData;
                    NSError * _Nullable error = nil;
                    [videoProject.managedObjectContext save:&error];
                    
                    if (error) {
                        completionHandler(nil, nil, nil, nil, nil, error);
                        return;
                    }
                    
                    dispatch_async(self.queue, ^{
                        self.queue_composition = composition;
                        self.queue_videoComposition = videoComposition;
                        self.queue_renderElements = renderElements;
                        self.queue_trackSegmentNames = trackSegmentNames;
                        self.queue_compositionIDs = compositionIDs;
                        [self queue_postCompositionDidChangeNotification];
                        
                        if (completionHandler) {
                            completionHandler(self.queue_composition, self.queue_videoComposition, self.queue_renderElements, self.queue_trackSegmentNames, self.queue_compositionIDs, nil);
                        }
                    });
                }];
            });
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
        EditorServiceTrackSegmentNamesKey: self.queue_trackSegmentNames
    }];
}

- (NSURL * _Nullable)copyToLocalFileFootageFromURL:(NSURL *)sourceURL error:(NSError * _Nullable * _Nullable)error __attribute__((objc_direct, ns_returns_autoreleased)) {
    NSURL *localFileFootagesURL = SVProjectsManager.sharedInstance.localFileFootagesURL;
    
    if (![NSFileManager.defaultManager fileExistsAtPath:localFileFootagesURL.path isDirectory:NULL]) {
        [NSFileManager.defaultManager createDirectoryAtURL:localFileFootagesURL withIntermediateDirectories:YES attributes:nil error:error];
        if (*error) {
            return nil;
        }
    }
    
    const char *sourcePath = [sourceURL.path cStringUsingEncoding:NSUTF8StringEncoding];
    NSURL *destinationURL = [[localFileFootagesURL URLByAppendingPathComponent:[NSUUID UUID].UUIDString] URLByAppendingPathExtension:sourceURL.pathExtension];
    const char *destinationPath = [destinationURL.path cStringUsingEncoding:NSUTF8StringEncoding];
    
    int result = clonefile(sourcePath, destinationPath, 0);
    
    if (result != 0) {
        [NSFileManager.defaultManager copyItemAtURL:sourceURL toURL:destinationURL error:error];
        if (*error) {
            return nil;
        }
    }
    
    return destinationURL;
}

- (NSProgress *)exportToURLWithQuality:(EditorServiceExportQuality)quality completionHandler:(void (^)(NSURL * _Nullable, NSError * _Nullable))completionHandler {
    NSProgress *progress = [NSProgress progressWithTotalUnitCount:1000000UL];
    
    dispatch_async(self.queue, ^{
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

@end
