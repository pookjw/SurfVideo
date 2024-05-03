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

- (NSDictionary<NSNumber *, NSDictionary<NSNumber *, NSString *> *> *)queue_trackSegmentNames {
    [self assertQueue];
    
    return _queue_trackSegmentNames;
}

- (void)queue_setTrackSegmentNames:(NSDictionary<NSNumber *, NSDictionary<NSNumber *, NSString *> *> *)queue_trackSegmentNames {
    [self assertQueue];
    
    [_queue_trackSegmentNames release];
    _queue_trackSegmentNames = [queue_trackSegmentNames copy];
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

- (void)contextQueue_mutableCompositionFromVideoProject:(SVVideoProject *)videoProject progressHandler:(void (^)(NSProgress *progress))progressHandler completionHandler:(void (^)(AVMutableComposition * _Nullable mutableComposition, NSDictionary<NSNumber *, NSArray<NSUUID *> *> * _Nullable compositionIDs,  NSError * _Nullable error))completionHandler {
    
    AVMutableComposition *mutableComposition = [AVMutableComposition composition];
    mutableComposition.naturalSize = CGSizeMake(1280.f, 720.f);
    [mutableComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:self.mainVideoTrackID];
    [mutableComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:self.audioTrackID];
    
    NSMutableDictionary<NSNumber *, NSMutableArray<NSUUID *> *> *compositionIDs = [NSMutableDictionary dictionary];
    
    NSOrderedSet<SVVideoClip *> *videoClips = videoProject.videoTrack.videoClips;
    NSOrderedSet<SVAudioClip *> *audioClips = videoProject.audioTrack.audioClips;
    
    NSProgress *progress = [NSProgress progressWithTotalUnitCount:videoClips.count + audioClips.count];
    progressHandler(progress);
    
    [self contextQueue_appendClipsToTrackFromClips:videoClips
                                           trackID:self.mainVideoTrackID
                                      videoProject:videoProject
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
        
        [self contextQueue_appendClipsToTrackFromClips:audioClips
                                               trackID:self.audioTrackID
                                          videoProject:videoProject
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
}

- (void)appendClipsToTrackFromPickerResults:(NSArray<PHPickerResult *> *)pickerResults trackID:(CMPersistentTrackID)trackID mutableComposition:(AVMutableComposition *)mutableComposition createFootage:(BOOL)createFootage videoProject:(SVVideoProject * _Nullable)videoProject progressHandler:(void (^)(NSProgress * _Nonnull))progressHandler completionHandler:(void (^)(AVMutableComposition * _Nullable mutableComposition, NSDictionary<NSString *, NSUUID *> * _Nullable createdCompositionIDs, NSDictionary<NSNumber *, NSString *> * _Nullable titlesByTrackSegmentIndex, NSError * _Nullable error))completionHandler {
    auto assetIdentifiers = [NSMutableArray<NSString *> new];
    
    for (PHPickerResult *result in pickerResults) {
        NSString *assetIdentifier = result.assetIdentifier;
        
        [assetIdentifiers addObject:assetIdentifier];
    }
    
    [self appendClipsToTrackFromAssetIdentifiers:assetIdentifiers
                                         trackID:trackID
                              mutableComposition:mutableComposition
                                   createFootage:createFootage
                                    videoProject:videoProject
                                 progressHandler:progressHandler
                               completionHandler:completionHandler];
    
    [assetIdentifiers release];
}

- (void)appendClipsToTrackFromAssetIdentifiers:(NSArray<NSString *> *)assetIdentifiers trackID:(CMPersistentTrackID)trackID mutableComposition:(AVMutableComposition *)mutableComposition createFootage:(BOOL)createFootage videoProject:(SVVideoProject * _Nullable)videoProject progressHandler:(void (^)(NSProgress * _Nonnull))progressHandler completionHandler:(void (^)(AVMutableComposition * _Nullable mutableComposition, NSDictionary<NSString *, NSUUID *> * _Nullable createdCompositionIDs, NSDictionary<NSNumber *, NSString *> * _Nullable titlesByTrackSegmentIndex, NSError * _Nullable error))completionHandler {
    NSManagedObjectContext *managedObjectContext = videoProject.managedObjectContext;
    NSUInteger assetIdentifiersCount = assetIdentifiers.count;
    PHImageManager *imageManager = PHImageManager.defaultManager;
    PHVideoRequestOptions *videoRequestOptions = [PHVideoRequestOptions new];
    videoRequestOptions.deliveryMode = PHVideoRequestOptionsDeliveryModeHighQualityFormat;
    videoRequestOptions.networkAccessAllowed = YES;
    
    NSMutableArray<AVAsset *> *avAssets = [[NSMutableArray alloc] initWithCapacity:assetIdentifiersCount];
    NSMutableDictionary<NSString *, AVAsset *> *avAssetsByAssetIdentifier = [[NSMutableDictionary alloc] initWithCapacity:assetIdentifiersCount];
    
    // Loading PHAssets + Loading AVAssets + Core Data Transaction
    int64_t progressTotalUnitCount;
    if (createFootage) {
        progressTotalUnitCount = assetIdentifiersCount * 2 + 1;
    } else {
        progressTotalUnitCount = assetIdentifiersCount * 2;
    }
    
    NSProgress *parentProgress = [NSProgress progressWithTotalUnitCount:progressTotalUnitCount];
    progressHandler(parentProgress);
    
    NSProgress *progress = [imageManager sv_requestAVAssetsForAssetIdentifiers:assetIdentifiers options:videoRequestOptions partialResultHandler:^(NSString * _Nullable assetIdentifier, AVAsset * _Nullable avAsset, AVAudioMix * _Nullable avAuioMix, NSDictionary * _Nullable info, PHAsset * _Nonnull asset, BOOL *stop, BOOL isEnd) {
        if (static_cast<NSNumber *>(info[PHImageCancelledKey]).boolValue) {
            *stop = YES;
            completionHandler(nil, nil, nil, [NSError errorWithDomain:SurfVideoErrorDomain code:SurfVideoUserCancelledError userInfo:nil]);
            return;
        }
        
        if (auto error = static_cast<NSError *>(info[PHImageErrorKey])) {
            *stop = YES;
            completionHandler(nil, nil, nil, error);
            return;
        }
        
        [avAssets addObject:avAsset];
        avAssetsByAssetIdentifier[assetIdentifier] = avAsset; 
        
        if (isEnd) {
            NSError * _Nullable error = nil;
            
            NSDictionary<NSString *, id> *result = [self appendClipsToTrackFromAVAssets:avAssets trackID:trackID mutableComposition:mutableComposition returnTitles:YES error:&error];
            parentProgress.completedUnitCount += 1;
            
            if (error) {
                completionHandler(nil, nil, nil, error);
                return;
            }
            
            AVMutableComposition *appendedMutableComposition = result[@"mutableComposition"];
            NSDictionary<AVAsset *, NSString *> *titlesByAVAsset = result[@"titlesByAVAsset"];
            NSDictionary<NSNumber *, NSString *> *titlesByTrackSegmentIndex = result[@"titlesByTrackSegmentIndex"];
            
            NSMutableDictionary<NSString *, NSString *> *titlesByAssetIdentifier = [[[NSMutableDictionary alloc] initWithCapacity:titlesByAVAsset.count] autorelease];
            
            [avAssetsByAssetIdentifier enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull assetIdentifier, AVAsset * _Nonnull avAsset, BOOL * _Nonnull stop) {
                NSString * _Nullable title = titlesByAVAsset[avAsset];
                
                if (title != nil) {
                    titlesByAssetIdentifier[assetIdentifier] = title;
                }
            }];
            
            if (createFootage) {
                [managedObjectContext sv_performBlock:^{
                    NSError * _Nullable error = nil;
                    
                    NSDictionary<NSString *, SVPHAssetFootage *> *phAssetFootages = [SVProjectsManager.sharedInstance contextQueue_phAssetFootagesFromAssetIdentifiers:assetIdentifiers createIfNeededWithoutSaving:YES managedObjectContext:managedObjectContext error:&error];
                    
                    NSMutableDictionary<NSString *, NSUUID *> *createdCompositionIDs = [[[NSMutableDictionary alloc] initWithCapacity:assetIdentifiersCount] autorelease];
                    
                    if (error) {
                        completionHandler(nil, nil, nil, error);
                        return;
                    }
                    
                    //
                    
                    if (trackID == self.mainVideoTrackID) {
                        SVVideoTrack *mainVideoTrack = videoProject.videoTrack;
                        
                        for (NSString *assetIdentifier in assetIdentifiers) {
                            AVAsset *avAsset = avAssetsByAssetIdentifier[assetIdentifier];
                            NSString * _Nullable title = titlesByAVAsset[avAsset];
                            
                            SVPHAssetFootage *phAssetFootage = phAssetFootages[assetIdentifier];
                            
                            SVVideoClip *videoClip = [[SVVideoClip alloc] initWithContext:managedObjectContext];
                            NSUUID *compositionID = [NSUUID UUID];
                            
                            videoClip.footage = phAssetFootage;
                            videoClip.compositionID = compositionID;
                            videoClip.name = title;
                            
                            [mainVideoTrack addVideoClipsObject:videoClip];
                            [videoClip release];
                            
                            createdCompositionIDs[assetIdentifier] = compositionID;
                        }
                    } else if (trackID == self.audioTrackID) {
                        SVAudioTrack *audioTrack = videoProject.audioTrack;
                        
                        for (NSString *assetIdentifier in assetIdentifiers) {
                            AVAsset *avAsset = avAssetsByAssetIdentifier[assetIdentifier];
                            NSString * _Nullable title = titlesByAVAsset[avAsset];
                            
                            SVPHAssetFootage *phAssetFootage = phAssetFootages[assetIdentifier];
                            
                            SVAudioClip *audioClip = [[SVAudioClip alloc] initWithContext:managedObjectContext];
                            NSUUID *compositionID = [NSUUID UUID];
                            
                            audioClip.footage = phAssetFootage;
                            audioClip.compositionID = compositionID;
                            audioClip.name = title;
                            
                            [audioTrack addAudioClipsObject:audioClip];
                            [audioClip release];
                            
                            createdCompositionIDs[assetIdentifier] = compositionID;
                        }
                    }
                    
                    [managedObjectContext save:&error];
                    
                    if (error) {
                        completionHandler(nil, nil, nil,error);
                        return;
                    }
                    
                    parentProgress.completedUnitCount += 1;
                    completionHandler(appendedMutableComposition, createdCompositionIDs, titlesByTrackSegmentIndex, nil);
                }];
            } else {
                completionHandler(appendedMutableComposition,  nil, titlesByTrackSegmentIndex, nil);
            }
        }
    }];
    
    [parentProgress addChild:progress withPendingUnitCount:assetIdentifiersCount];
    
    [videoRequestOptions release];
    [avAssets release];
    [avAssetsByAssetIdentifier release];
}

- (NSDictionary<NSString *,id> *)contextQueue_footageURLsByCreatingSVClipsFromSourceURLs:(NSArray<NSURL *> *)sourceURLs videoProject:(SVVideoProject *)videoProject trackID:(CMPersistentTrackID)trackID error:(NSError * _Nullable *)error {
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
        
        if (title != nil) {
            titlesBySourceURL[sourceURL] = title;
        }
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

- (AVMutableComposition * _Nullable)appendClipsToTrackFromURLs:(NSArray<NSURL *> *)urls trackID:(CMPersistentTrackID)trackID mutableComposition:(AVMutableComposition *)mutableComposition error:(NSError **)error {
    NSMutableArray<AVURLAsset *> *avAssets = [[[NSMutableArray alloc] initWithCapacity:urls.count] autorelease];
    
    for (NSURL *url in urls) {
        AVURLAsset *avAsset = [AVURLAsset assetWithURL:url];
        [avAssets addObject:avAsset];
    }
    
    NSDictionary<NSString *, id> *result = [self appendClipsToTrackFromAVAssets:avAssets trackID:trackID mutableComposition:mutableComposition returnTitles:NO error:error];
    
    if (*error) {
        return nil;
    }
    
    return result[@"mutableComposition"];
}

- (NSDictionary<NSString *, id> * _Nullable)appendClipsToTrackFromAVAssets:(NSArray<AVAsset *> *)avAssets trackID:(CMPersistentTrackID)trackID mutableComposition:(AVMutableComposition *)mutableComposition returnTitles:(BOOL)returnTitles error:(NSError * _Nullable * _Nullable)error {
    AVMutableCompositionTrack *compositionTrack = [mutableComposition trackWithTrackID:trackID];
    
    if (compositionTrack == nil) {
        if (error) {
            *error = [NSError errorWithDomain:SurfVideoErrorDomain code:SurfVideoNoTrackFoundError userInfo:nil];
        }
        
        return nil;
    }
    
    //
    
    NSMutableDictionary<AVAsset *, NSString *> *titlesByAVAsset = [NSMutableDictionary dictionary];
    NSMutableDictionary<NSNumber *, NSString *> *titlesByTrackSegmentIndex = [NSMutableDictionary dictionary];
    
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
            
            //
            
            NSString * _Nullable title = nil;
            for (AVMetadataItem *metadataItem in avAsset.metadata) {
                if ([metadataItem.commonKey isEqualToString:AVMetadataCommonKeyTitle]) {
                    title = static_cast<NSString *>(metadataItem.value);
                    break;
                }
            }
            
            if (title != nil) {
                titlesByAVAsset[avAsset] = title;
                titlesByTrackSegmentIndex[@(compositionTrack.segments.count - 1)] = title;
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
            
            //
            
            NSString * _Nullable title = nil;
            for (AVMetadataItem *metadataItem in avAsset.metadata) {
                if ([metadataItem.commonKey isEqualToString:AVMetadataCommonKeyTitle]) {
                    title = static_cast<NSString *>(metadataItem.value);
                    break;
                }
            }
            
            if (title != nil) {
                titlesByAVAsset[avAsset] = title;
                titlesByTrackSegmentIndex[@(compositionTrack.segments.count - 1)] = title;
            }
        }
    } else {
        if (error) {
            *error = [NSError errorWithDomain:SurfVideoErrorDomain code:SurfVideoUnknownTrackID userInfo:nil];
        }
        return nil;
    }
    
    return @{
        @"mutableComposition": mutableComposition,
        @"titlesByAVAsset": titlesByAVAsset,
        @"titlesByTrackSegmentIndex": titlesByTrackSegmentIndex
    };
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
                                    videoProject:(SVVideoProject *)videoProject
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
        [videoProject.managedObjectContext sv_performBlock:^{
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
                                              videoProject:videoProject
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
        
        [self appendClipsToTrackFromAssetIdentifiers:@[assetIdentifier]
                                             trackID:trackID
                                  mutableComposition:mutableComposition
                                       createFootage:createFootage
                                        videoProject:videoProject
                                     progressHandler:^(NSProgress *progress) {
            [parentProgress addChild:progress withPendingUnitCount:1000000LL];
        }
                                   completionHandler:^(AVMutableComposition * _Nullable mutableComposition, NSDictionary<NSString *,NSUUID *> * _Nullable createdCompositionIDs, NSDictionary<NSNumber *, NSString *> * _Nullable titlesByTrackSegmentIndex, NSError * _Nullable error) {
            appendCompositionCompletionHandler(mutableComposition, error);
        }];
    } else if ([footage.entity.name isEqualToString:@"LocalFileFootage"]) {
        auto localFileFootage = static_cast<SVLocalFileFootage *>(footage);
        NSString *lastPathCompoent = localFileFootage.fileName;
        NSURL *URL = [SVProjectsManager.sharedInstance.localFileFootagesURL URLByAppendingPathComponent:lastPathCompoent];
        
        NSError * _Nullable error = nil;
        AVMutableComposition *resultMutableComposition = [self appendClipsToTrackFromURLs:@[URL] trackID:trackID mutableComposition:mutableComposition error:&error];
        parentProgress.completedUnitCount += 1000000LL;
        
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

- (NSDictionary<NSNumber *,NSDictionary<NSNumber *,NSString *> *> *)contextQueue_trackSegmentNamesFromCompositionIDs:(NSDictionary<NSNumber *,NSArray<NSUUID *> *> *)compositionIDs videoProject:(SVVideoProject *)videoProject {
    NSManagedObjectContext *managedObjectContext = videoProject.managedObjectContext;
    NSMutableDictionary<NSNumber *, NSDictionary<NSNumber *, NSString *> *> *trackSegmentNames = [NSMutableDictionary new];
    
    [compositionIDs enumerateKeysAndObjectsUsingBlock:^(NSNumber * _Nonnull trackIDNumber, NSArray<NSUUID *> * _Nonnull compositionIDArray, BOOL * _Nonnull stop) {
        NSMutableDictionary<NSNumber *, NSString *> *trackSegmentNameDictionary = [NSMutableDictionary new];
        
        [compositionIDArray enumerateObjectsUsingBlock:^(NSUUID * _Nonnull compositionID, NSUInteger idx, BOOL * _Nonnull stop) {
            NSFetchRequest<SVClip *> *fetchRequest = [SVClip fetchRequest];
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K == %@" argumentArray:@[@"compositionID", compositionID]];
            
            fetchRequest.predicate = predicate;
            fetchRequest.fetchLimit = 1;
            
            NSError * _Nullable error = nil;
            NSArray<SVClip *> *fetchedObjects = [managedObjectContext executeFetchRequest:fetchRequest error:&error];
            assert(error == nil);
            assert(fetchedObjects.count == 1);
            
            SVClip *clip = fetchedObjects.firstObject;
            NSString *name = clip.name;
            
            if (name != nil) {
                trackSegmentNameDictionary[@(idx)] = name;
            }
        }];
        
        trackSegmentNames[trackIDNumber] = trackSegmentNameDictionary;
        [trackSegmentNameDictionary release];
    }];
    
    return [trackSegmentNames autorelease];
}

- (void)contextQueue_finalizeWithVideoProject:(SVVideoProject *)videoProject
                                  composition:(AVComposition *)composition
                               compositionIDs:(NSDictionary<NSNumber *, NSArray<NSUUID *> *> *)compositionIDs
                            trackSegmentNames:(NSDictionary<NSNumber *,NSDictionary<NSNumber *,NSString *> *> *)trackSegmentNames
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
                    self.queue_trackSegmentNames = trackSegmentNames;
                    self.queue_compositionIDs = compositionIDs;
                    [self queue_postCompositionDidChangeNotification];
                    
                    if (completionHandler) {
                        completionHandler(self.queue_composition, self.queue_videoComposition, self.queue_renderElements, self.queue_trackSegmentNames, self.queue_compositionIDs, nil);
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
        EditorServiceTrackSegmentNamesKey: self.queue_trackSegmentNames
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

- (NSDictionary<NSNumber *,NSDictionary<NSNumber *,NSString *> *> *)appendingTrackSegmentNames:(NSDictionary<NSNumber *,NSString *> *)addingTrackSegmentNames trackID:(CMPersistentTrackID)trackID intoTrackSegmentNames:(NSDictionary<NSNumber *,NSDictionary<NSNumber *,NSString *> *> *)trackSegmentNames {
    if (addingTrackSegmentNames.count == 0) return trackSegmentNames;
    
    NSMutableDictionary<NSNumber *, NSDictionary<NSNumber *, NSString *> *> *mutableTrackSegmentNames = [trackSegmentNames mutableCopy];
    
    if (NSMutableDictionary<NSNumber *, NSString *> *mutableTrackSegmentNameDictionary = [mutableTrackSegmentNames[@(trackID)] mutableCopy]) {
        [mutableTrackSegmentNameDictionary addEntriesFromDictionary:addingTrackSegmentNames];
        mutableTrackSegmentNames[@(trackID)] = mutableTrackSegmentNameDictionary;
        [mutableTrackSegmentNameDictionary release];
    } else {
        mutableTrackSegmentNames[@(trackID)] = addingTrackSegmentNames;
    }
    
    return [mutableTrackSegmentNames autorelease];
}

- (NSDictionary<NSNumber *,NSDictionary<NSNumber *,NSString *> *> *)deletingTrackSegmentNames:(NSDictionary<NSNumber *,NSString *> *)deletingTrackSegmentNames trackID:(CMPersistentTrackID)trackID fromTrackSegmentNames:(NSDictionary<NSNumber *,NSDictionary<NSNumber *,NSString *> *> *)trackSegmentNames {
    if (deletingTrackSegmentNames.count == 0) return trackSegmentNames;
    if (trackSegmentNames[@(trackID)] == nil) return trackSegmentNames;
    
    NSMutableDictionary<NSNumber *, NSDictionary<NSNumber *, NSString *> *> *mutableTrackSegmentNames = [trackSegmentNames mutableCopy];
    
    if (NSMutableDictionary<NSNumber *, NSString *> *mutableTrackSegmentNameDictionary = [mutableTrackSegmentNames[@(trackID)] mutableCopy]) {
        [mutableTrackSegmentNameDictionary removeObjectsForKeys:deletingTrackSegmentNames.allKeys];
        
        mutableTrackSegmentNames[@(trackID)] = mutableTrackSegmentNameDictionary;
        [mutableTrackSegmentNameDictionary release];
    }
    
    return [mutableTrackSegmentNames autorelease];
}

- (NSDictionary<NSNumber *,NSDictionary<NSNumber *,NSString *> *> *)addingTrackSegmentNamesByCompositionID:(NSDictionary<NSUUID *,NSString *> *)trackSegmentNamesByCompositionID compositionIDs:(NSDictionary<NSNumber *,NSArray<NSUUID *> *> *)compositionIDs trackID:(CMPersistentTrackID)trackID intoTrackSegmentNames:(NSDictionary<NSNumber *,NSDictionary<NSNumber *,NSString *> *> *)trackSegmentNames {
    if (trackSegmentNamesByCompositionID.count == 0) return trackSegmentNames;
    
    NSMutableDictionary<NSNumber *, NSDictionary<NSNumber * ,NSString *> *> *mutableTrackSegmentNames = [trackSegmentNames mutableCopy];
    
    NSMutableDictionary<NSNumber *, NSString *> *mutableTrackSegmentDictionary;
    if (id _mutableTrackSegmentDictionary = [mutableTrackSegmentNames[@(trackID)] mutableCopy]) {
        mutableTrackSegmentDictionary = [_mutableTrackSegmentDictionary autorelease];
    } else {
        mutableTrackSegmentDictionary = [NSMutableDictionary dictionary];
    }
    
    NSArray<NSUUID *> *compositionIDArray = compositionIDs[@(trackID)];
    
    [trackSegmentNamesByCompositionID enumerateKeysAndObjectsUsingBlock:^(NSUUID * _Nonnull compositionID, NSString * _Nonnull trackSegmentName, BOOL * _Nonnull stop) {
        NSInteger index = [compositionIDArray indexOfObject:compositionID];
        assert(index != NSNotFound);
        
        mutableTrackSegmentDictionary[@(index)] = trackSegmentName;
    }];
    
    mutableTrackSegmentNames[@(trackID)] = mutableTrackSegmentDictionary;
    
    return [mutableTrackSegmentNames autorelease];
}

- (void)appendClipsFromURLs:(NSArray<NSURL *> *)urls intoTrackID:(CMPersistentTrackID)trackID progressHandler:(void (^)(NSProgress * _Nonnull))progressHandler completionHandler:(void (^)(AVComposition * _Nullable, AVVideoComposition * _Nullable, NSArray<__kindof EditorRenderElement *> * _Nullable, NSDictionary<NSNumber *,NSDictionary<NSNumber *,NSString *> *> * _Nullable, NSDictionary<NSNumber *,NSArray<NSUUID *> *> * _Nullable, NSError * _Nullable))completionHandler {
    dispatch_async(self.queue_1, ^{
        dispatch_suspend(self.queue_1);
        
        AVMutableComposition *mutableComposition = [self.queue_composition mutableCopy];
        SVVideoProject *videoProject = self.queue_videoProject;
        NSDictionary<NSNumber *, NSArray<NSUUID *> *> *compositionIDs = self.queue_compositionIDs;
        NSArray<__kindof EditorRenderElement *> *renderElements = self.queue_renderElements;
        NSDictionary<NSNumber *, NSDictionary<NSNumber *, NSString *> *> *trackSegmentNames = self.queue_trackSegmentNames;
        NSManagedObjectContext *managedObjectContext = videoProject.managedObjectContext;
        
        [managedObjectContext performBlock:^{
            NSError * _Nullable error = nil;
            NSDictionary<NSString *, id> *results = [self contextQueue_footageURLsByCreatingSVClipsFromSourceURLs:urls videoProject:videoProject trackID:trackID error:&error];
            
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
            
            NSDictionary<NSNumber *,NSArray<NSUUID *> *> *newCompositionIDs = [self appendingCompositionIDArray:createdCompositionIDArray trackID:trackID intoCompositionIDs:compositionIDs];
            NSDictionary<NSNumber *, NSDictionary<NSNumber *, NSString *> *> *newTrackSegmentNames = [self addingTrackSegmentNamesByCompositionID:titlesByCompositionID compositionIDs:newCompositionIDs trackID:trackID intoTrackSegmentNames:trackSegmentNames];
            
            if (error != nil) {
                completionHandler(nil, nil, nil, nil, nil, error);
                dispatch_resume(self.queue_1);
                return;
            }
            
            [self contextQueue_finalizeWithVideoProject:videoProject
                                            composition:resultMutableComposition
                                         compositionIDs:newCompositionIDs
                                      trackSegmentNames:newTrackSegmentNames
                                         renderElements:renderElements
                                      completionHandler:^(AVComposition * _Nullable composition, AVVideoComposition * _Nullable videoComposition, NSArray<__kindof EditorRenderElement *> * _Nullable renderElements, NSDictionary<NSNumber *,NSDictionary<NSNumber *,NSString *> *> * _Nullable trackSegmentNames, NSDictionary<NSNumber *,NSArray<NSUUID *> *> * _Nullable compositionIDs, NSError * _Nullable error) {
                completionHandler(composition, videoComposition, renderElements, trackSegmentNames, compositionIDs, error);
                dispatch_resume(self.queue_1);
            }];
        }];
        
        [mutableComposition release];
    });
}

@end
