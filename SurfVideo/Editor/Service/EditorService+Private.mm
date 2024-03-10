//
//  EditorService+Private.mm
//  SurfVideo
//
//  Created by Jinwoo Kim on 3/1/24.
//

#import "EditorService+Private.hpp"
#import "constants.hpp"
#import "PHImageManager+RequestAVAssets.hpp"
#import "AVAsset+Private.h"
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
    return _queue_videoProject;
}

- (void)queue_setVideoProject:(SVVideoProject *)queue_videoProject {
    [_queue_videoProject release];
    _queue_videoProject = [queue_videoProject retain];
}

- (NSSet<NSUserActivity *> *)userActivities {
    return _userActivities;
}

- (AVComposition *)queue_composition {
    return _queue_composition;
}

- (void)queue_setComposition:(AVComposition *)queue_composition {
    [_queue_composition release];
    _queue_composition = [queue_composition copy];
}

- (AVVideoComposition *)queue_videoComposition {
    return _queue_videoComposition;
}

- (void)queue_setVideoComposition:(AVVideoComposition *)queue_videoComposition {
    [_queue_videoComposition release];
    _queue_videoComposition = [queue_videoComposition copy];
}

- (NSArray<__kindof EditorRenderElement *> *)queue_renderElements {
    return _queue_renderElements;
}

- (void)queue_setRenderElements:(NSArray<__kindof EditorRenderElement *> *)queue_renderElements {
    [_queue_renderElements release];
    _queue_renderElements = [queue_renderElements copy];
}

- (NSDictionary<NSNumber *,NSArray *> *)queue_trackSegmentNames {
    return _queue_trackSegmentNames;
}

- (void)queue_setTrackSegmentNames:(NSDictionary<NSNumber *,NSArray *> *)queue_trackSegmentNames {
    [_queue_trackSegmentNames release];
    _queue_trackSegmentNames = [queue_trackSegmentNames copy];
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

- (void)queue_mutableCompositionFromVideoProject:(SVVideoProject *)videoProject progressHandler:(void (^)(NSProgress *progress))progressHandler completionHandler:(void (^)(AVMutableComposition * _Nullable mutableComposition, NSError * _Nullable error))completionHandler {
    NSManagedObjectContext * _Nullable managedObjectContext = videoProject.managedObjectContext;
    if (!managedObjectContext) {
        completionHandler(nil, [NSError errorWithDomain:SurfVideoErrorDomain code:SurfVideoNoManagedObjectContextError userInfo:nil]);
        return;
    }
    
    AVMutableComposition *mutableComposition = [AVMutableComposition composition];
    mutableComposition.naturalSize = CGSizeMake(1280.f, 720.f);
    [mutableComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:self.mainVideoTrackID];
    [mutableComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:self.audioTrackID];
    
    [managedObjectContext performBlock:^{
        NSOrderedSet<SVVideoClip *> *videoClips = videoProject.videoTrack.videoClips;
        NSOrderedSet<SVAudioClip *> *audioClips = videoProject.audioTrack.audioClips;
        
        NSProgress *progress = [NSProgress progressWithTotalUnitCount:videoClips.count + audioClips.count];
        progressHandler(progress);
        
        [self contextQueue_appendClipsToTrackFromClips:videoClips trackID:self.mainVideoTrackID managedObjectContext:managedObjectContext mutableComposition:mutableComposition createFootage:NO index:0 parentProgress:progress completionHandler:^(AVMutableComposition * _Nullable mutableComposition, NSError * _Nullable error) {
            if (error) {
                completionHandler(nil, error);
                return;
            }
            
            [managedObjectContext performBlock:^{
                [self contextQueue_appendClipsToTrackFromClips:audioClips trackID:self.audioTrackID managedObjectContext:managedObjectContext mutableComposition:mutableComposition createFootage:NO index:0 parentProgress:progress completionHandler:^(AVMutableComposition * _Nullable mutableComposition, NSError * _Nullable error) {
                    if (error) {
                        completionHandler(nil, error);
                        return;
                    }
                    
                    completionHandler(mutableComposition, error);
                }];
            }];
        }];
    }];
}

- (void)appendClipsToTrackFromPickerResults:(NSArray<PHPickerResult *> *)pickerResults trackID:(CMPersistentTrackID)trackID mutableComposition:(AVMutableComposition *)mutableComposition createFootage:(BOOL)createFootage progressHandler:(void (^)(NSProgress * _Nonnull))progressHandler completionHandler:(void (^)(AVMutableComposition * _Nullable, NSError * _Nullable))completionHandler {
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

- (void)queue_appendClipsToTrackFromAssetIdentifiers:(NSArray<NSString *> *)assetIdentifiers trackID:(CMPersistentTrackID)trackID mutableComposition:(AVMutableComposition *)mutableComposition createFootage:(BOOL)createFootage progressHandler:(void (^)(NSProgress * _Nonnull))progressHandler completionHandler:(void (^)(AVMutableComposition * _Nullable mutableComposition, NSError * _Nullable))completionHandler {
    SVVideoProject *videoProject = self.queue_videoProject;
    NSManagedObjectContext *managedObjectContext = videoProject.managedObjectContext;
    NSUInteger assetIdentifiersCount = assetIdentifiers.count;
    PHImageManager *imageManager = PHImageManager.defaultManager;
    PHVideoRequestOptions *videoRequestOptions = [PHVideoRequestOptions new];
    videoRequestOptions.deliveryMode = PHVideoRequestOptionsDeliveryModeHighQualityFormat;
    videoRequestOptions.networkAccessAllowed = YES;
    
    NSMutableArray<AVAsset *> *avAssets = [[NSMutableArray<AVAsset *> alloc] initWithCapacity:assetIdentifiers.count];
    
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
            completionHandler(nil, [NSError errorWithDomain:SurfVideoErrorDomain code:SurfVideoUserCancelledError userInfo:nil]);
            return;
        }
        
        if (auto error = static_cast<NSError *>(info[PHImageErrorKey])) {
            *stop = YES;
            completionHandler(nil, error);
            return;
        }
        
        [avAssets addObject:avAsset];
        
        if (isEnd) {
            dispatch_async(self.queue, ^{
                NSError * _Nullable error = nil;
                
                [self appendClipsToTrackFromAVAssets:avAssets trackID:trackID progress:parentProgress progressUnit:1 mutableComposition:mutableComposition error:&error];
                
                if (error) {
                    completionHandler(nil, error);
                    return;
                }
                
                if (createFootage) {
                    [managedObjectContext performBlock:^{
                        NSError * _Nullable error = nil;
                        
                        NSDictionary<NSString *, SVPHAssetFootage *> *phAssetFootages = [SVProjectsManager.sharedInstance contextQueue_phAssetFootagesFromAssetIdentifiers:assetIdentifiers createIfNeededWithoutSaving:YES managedObjectContext:managedObjectContext error:&error];
                        
                        if (error) {
                            completionHandler(nil, error);
                            return;
                        }
                        
                        //
                        
                        if (trackID == self.mainVideoTrackID) {
                            SVVideoTrack *mainVideoTrack = videoProject.videoTrack;
                            
                            for (NSString *assetIdentifier in assetIdentifiers) {
                                SVPHAssetFootage *phAssetFootage = phAssetFootages[assetIdentifier];
                                
                                SVVideoClip *videoClip = [[SVVideoClip alloc] initWithContext:managedObjectContext];
                                videoClip.footage = phAssetFootage;
                                
                                [mainVideoTrack addVideoClipsObject:videoClip];
                                [videoClip release];
                            }
                        } else if (trackID == self.audioTrackID) {
                            SVAudioTrack *audioTrack = videoProject.audioTrack;
                            
                            for (NSString *assetIdentifier in assetIdentifiers) {
                                SVPHAssetFootage *phAssetFootage = phAssetFootages[assetIdentifier];
                                
                                SVAudioClip *audioClip = [[SVAudioClip alloc] initWithContext:managedObjectContext];
                                audioClip.footage = phAssetFootage;
                                
                                [audioTrack addAudioClipsObject:audioClip];
                                [audioClip release];
                            }
                        }
                        
                        [managedObjectContext save:&error];
                        
                        if (error) {
                            completionHandler(nil, error);
                            return;
                        }
                        
                        parentProgress.completedUnitCount += 1;
                        completionHandler(mutableComposition, nil);
                    }];
                } else {
                    completionHandler(mutableComposition, nil);
                }
            });
        }
    }];
    
    [parentProgress addChild:progress withPendingUnitCount:assetIdentifiersCount];
    
    [videoRequestOptions release];
    [avAssets release];
}

- (void)queue_appendClipsToTrackFromURLs:(NSArray<NSURL *> *)URLs trackID:(CMPersistentTrackID)trackID mutableComposition:(AVMutableComposition *)mutableComposition createFootage:(BOOL)createFootage progressHandler:(void (^)(NSProgress * _Nonnull))progressHandler completionHandler:(void (^)(AVMutableComposition * _Nullable, NSError * _Nullable))completionHandler {
    // AVAssets Creation = 1, Core Data Transaction = 1
    int64_t progressTotalCount;
    if (createFootage) {
        progressTotalCount = URLs.count + 1;
    } else {
        progressTotalCount = URLs.count + 2;
    }
    
    NSProgress *progress = [NSProgress progressWithTotalUnitCount:progressTotalCount];
    progressHandler(progress);
    
    SVVideoProject *videoProject = self.queue_videoProject;
    NSManagedObjectContext *managedObjectContext = videoProject.managedObjectContext;
    NSMutableArray<AVAsset *> *avAssets = [[[NSMutableArray<AVAsset *> alloc] initWithCapacity:URLs.count] autorelease];
    
    //
    
    for (NSURL *sourceURL in URLs) {
        NSURL *assetURL;
        if (createFootage) {
            NSError * _Nullable error = nil;
            assetURL = [self copyToLocalFileFootageFromURL:sourceURL error:&error];
            
            if (error) {
                completionHandler(nil, error);
                return;
            }
        } else {
            assetURL = sourceURL;
        }
        
        AVAsset *avAsset = [AVAsset assetWithURL:assetURL];
        [avAssets addObject:avAsset];
    }
    
    progress.completedUnitCount += 1;
    
    //
    
    NSError * _Nullable error = nil;
    [self appendClipsToTrackFromAVAssets:avAssets trackID:trackID progress:progress progressUnit:1 mutableComposition:mutableComposition error:&error];
    
    if (error) {
        completionHandler(nil, error);
        return;
    }
    
    if (createFootage) {
        [managedObjectContext performBlock:^{
            if (trackID == self.mainVideoTrackID) {
                SVVideoTrack *mainVideoTrack = videoProject.videoTrack;
                
                for (AVAsset *avAsset in avAssets) {
                    SVLocalFileFootage *localFileFootage = [[SVLocalFileFootage alloc] initWithContext:managedObjectContext];
                    localFileFootage.lastPathComponent = avAsset._absoluteURL.lastPathComponent;
                    
                    SVVideoClip *videoClip = [[SVVideoClip alloc] initWithContext:managedObjectContext];
                    videoClip.footage = localFileFootage;
                    [localFileFootage release];
                    
                    [mainVideoTrack addVideoClipsObject:videoClip];
                    [videoClip release];
                }
            } else if (trackID == self.audioTrackID) {
                SVAudioTrack *audioTrack = videoProject.audioTrack;
                
                for (AVAsset *avAsset in avAssets) {
                    NSString * _Nullable title = nil;
                    for (AVMetadataItem *metadataItem in avAsset.metadata) {
                        if ([metadataItem.commonKey isEqualToString:AVMetadataCommonKeyTitle]) {
                            title = static_cast<NSString *>(metadataItem.value);
                            break;
                        }
                    }
                    
                    SVLocalFileFootage *localFileFootage = [[SVLocalFileFootage alloc] initWithContext:managedObjectContext];
                    localFileFootage.lastPathComponent = avAsset._absoluteURL.lastPathComponent;
                    
                    SVAudioClip *audioClip = [[SVAudioClip alloc] initWithContext:managedObjectContext];
                    audioClip.footage = localFileFootage;
                    audioClip.name = title;
                    [localFileFootage release];
                    
                    [audioTrack addAudioClipsObject:audioClip];
                    [audioClip release];
                }
            }
            
            NSError * _Nullable error = nil;
            [managedObjectContext save:&error];
            
            if (error) {
                completionHandler(nil, error);
                return;
            }
            
            progress.completedUnitCount += 1;
            completionHandler(mutableComposition, nil);
        }];
    } else {
        completionHandler(mutableComposition, nil);
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

- (void)queue_removeTrackSegment:(AVCompositionTrackSegment *)trackSegment trackID:(CMPersistentTrackID)trackID mutableComposition:(AVMutableComposition *)mutableComposition completionHandler:(void (^)(AVMutableComposition * _Nullable, NSError * _Nullable))completionHandler {
    AVMutableCompositionTrack * _Nullable compositionTrack = [mutableComposition trackWithTrackID:trackID];
    if (compositionTrack == nil) {
        completionHandler(nil, [NSError errorWithDomain:SurfVideoErrorDomain code:SurfVideoNoTrackFoundError userInfo:nil]);
        return;
    }
    
    NSArray<AVCompositionTrackSegment *> *oldSegments = compositionTrack.segments;
    NSUInteger index = [oldSegments indexOfObject:trackSegment];
    [compositionTrack removeTimeRange:trackSegment.timeMapping.target];
    
    SVVideoProject *videoProject = self.queue_videoProject;
    NSManagedObjectContext *managedObjectContext = videoProject.managedObjectContext;
    
    [managedObjectContext performBlock:^{
        if (trackID == self.mainVideoTrackID) {
            SVVideoTrack *videotrack = videoProject.videoTrack;
            int64_t count = videotrack.videoClipsCount;
            
            assert(count == oldSegments.count);
            
            // NSCascadeDeleteRule여도 SVClip 자체가 사라지진 않음. deleteRule은 NSOrderedSet 자체가 사라질 때 처리
//            [videotrack removeObjectFromVideoClipsAtIndex:index];
            
            SVVideoClip *videoClip = videotrack.videoClips[index];
            [managedObjectContext deleteObject:videoClip];
        } else if (trackID == self.audioTrackID) {
            SVAudioTrack *audioTrack = videoProject.audioTrack;
            int64_t count = audioTrack.audioClipsCount;
            
            assert(count == oldSegments.count);
            
//            [audioTrack removeObjectFromAudioClipsAtIndex:index];
            
            SVAudioClip *audioClip = audioTrack.audioClips[index];
            [managedObjectContext deleteObject:audioClip];
        }
        
        NSError * _Nullable error = nil;
        [managedObjectContext save:&error];
        
        if (error) {
            completionHandler(nil, error);
            return;
        }
        
        completionHandler(mutableComposition, nil);
    }];
}

- (void)contextQueue_appendClipsToTrackFromClips:(NSOrderedSet<SVClip *> *)clips trackID:(CMPersistentTrackID)trackID managedObjectContext:(NSManagedObjectContext *)managedObjectContext mutableComposition:(AVMutableComposition *)mutableComposition createFootage:(BOOL)createFootage index:(NSUInteger)index parentProgress:(NSProgress *)parentProgress completionHandler:(void (^)(AVMutableComposition * _Nullable mutableComposition, NSError * _Nullable error))completionHandler __attribute__((objc_direct)) {
    if (clips.count <= index) {
        completionHandler(mutableComposition, nil);
        return;
    }
    
    SVClip *clip = clips[index];
    SVFootage *footage = clip.footage;
    NSUInteger clipsCount = clips.count;
    
    void (^appendCompositionCompletionHandler)(AVMutableComposition * _Nullable mutableComposition, NSError * _Nullable error) = ^(AVMutableComposition * _Nullable mutableComposition, NSError * _Nullable error) {
        [managedObjectContext performBlock:^{
            if (error) {
                completionHandler(nil, error);
                return;
            }
            
            NSUInteger nextIndex = index + 1;
            
            if (clipsCount <= nextIndex) {
                completionHandler(mutableComposition, nil);
                return;
            }
            
            [self contextQueue_appendClipsToTrackFromClips:clips
                                                   trackID:trackID
                                      managedObjectContext:managedObjectContext
                                                       mutableComposition:mutableComposition
                                                            createFootage:createFootage
                                                                    index:nextIndex
                                                           parentProgress:parentProgress
                                                        completionHandler:completionHandler];
        }];
    };
    
    if ([footage isKindOfClass:SVPHAssetFootage.class]) {
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
                                             completionHandler:appendCompositionCompletionHandler];
        });
    } else if ([footage isKindOfClass:SVLocalFileFootage.class]) {
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
                                 completionHandler:appendCompositionCompletionHandler];
        });
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
                                                                                            objectID:caption.objectID];
        
        [results addObject:rendererCaption];
        
        [rendererCaption release];
    }
    
    return [results autorelease];
}

- (void)contextQueue_videoCompositionAndRenderElementsFromComposition:(AVComposition *)composition
                                                    completionHandler:(void (^)(AVVideoComposition * _Nullable videoComposition, NSArray<__kindof EditorRenderElement *> * _Nullable renderElements, NSError * _Nullable error))completionHandler {
    NSArray<__kindof EditorRenderElement *> *elements = [self contextQueue_renderElementsFromVideoProject:self.queue_videoProject];
    
    dispatch_async(self.queue, ^{
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
    });
}

- (NSDictionary<NSNumber *, NSArray *> *)contextQueue_trackSegmentNamesFromComposition:(AVComposition *)composition videoProject:(SVVideoProject *)videoProject {
    auto trackSegmentNames = [NSMutableDictionary<NSNumber *, NSArray *> new];
    
    if (AVCompositionTrack *mainVideoTrack = [composition trackWithTrackID:self.mainVideoTrackID]) {
        NSUInteger count = mainVideoTrack.segments.count;
        
        if (count > 0) {
            SVVideoTrack *svVideoTrack = videoProject.videoTrack;
            assert(count == svVideoTrack.videoClipsCount);
            auto names = [NSMutableArray new];
            
            [mainVideoTrack.segments enumerateObjectsUsingBlock:^(AVCompositionTrackSegment * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                SVVideoClip *videoClip = svVideoTrack.videoClips[idx];
                
                if (auto name = videoClip.name) {
                    [names addObject:name];
                } else {
                    [names addObject:NSNull.null];
                }
            }];
            
            trackSegmentNames[@(self.mainVideoTrackID)] = names;
            [names release];
        }
    }
    
    if (AVCompositionTrack *audioideoTrack = [composition trackWithTrackID:self.audioTrackID]) {
        NSUInteger count = audioideoTrack.segments.count;
        
        if (count > 0) {
            SVAudioTrack *svAudioTrack = videoProject.audioTrack;
            assert(count == svAudioTrack.audioClipsCount);
            auto names = [NSMutableArray new];
            
            [audioideoTrack.segments enumerateObjectsUsingBlock:^(AVCompositionTrackSegment * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                SVAudioClip *audioClip = svAudioTrack.audioClips[idx];
                
                if (auto name = audioClip.name) {
                    [names addObject:name];
                } else {
                    [names addObject:NSNull.null];
                }
            }];
            
            trackSegmentNames[@(self.audioTrackID)] = names;
            [names release];
        }
    }
    
    return [trackSegmentNames autorelease];
}

- (void)contextQueue_finalizeWithComposition:(AVComposition *)composition
                                videoProject:(SVVideoProject *)videoProject
                           completionHandler:(EditorServiceCompletionHandler)completionHandler {
    NSDictionary<NSNumber *, NSArray *> *trackSegmentNames = [self contextQueue_trackSegmentNamesFromComposition:composition videoProject:videoProject];
    
    [self contextQueue_videoCompositionAndRenderElementsFromComposition:composition completionHandler:^(AVVideoComposition * _Nullable videoComposition, NSArray<__kindof EditorRenderElement *> * _Nullable renderElements, NSError * _Nullable error) {
        if (error) {
            completionHandler(nil, nil, nil, nil, error);
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
                completionHandler(nil, nil, nil, nil, error);
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
                        completionHandler(nil, nil, nil, nil, error);
                        return;
                    }
                    
                    dispatch_async(self.queue, ^{
                        self.queue_composition = composition;
                        self.queue_videoComposition = videoComposition;
                        self.queue_renderElements = renderElements;
                        self.queue_trackSegmentNames = trackSegmentNames;
                        [self queue_postCompositionDidChangeNotification];
                        
                        if (completionHandler) {
                            completionHandler(self.queue_composition, self.queue_videoComposition, self.queue_renderElements, self.queue_trackSegmentNames, nil);
                        }
                    });
                }];
            });
        }];
    }];
}

- (void)queue_postCompositionDidChangeNotification {
    [NSNotificationCenter.defaultCenter postNotificationName:EditorServiceCompositionDidChangeNotification
                                                      object:self 
                                                    userInfo:@{
        EditorServiceCompositionKey: self.queue_composition,
        EditorServiceVideoCompositionKey: self.queue_videoComposition,
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

@end
