//
//  EditorService.mm
//  SurfVideo
//
//  Created by Jinwoo Kim on 12/15/23.
//

#import "EditorService.hpp"
#import "SVProjectsManager.hpp"
#import "constants.hpp"
#import "PHImageManager+RequestAVAssets.hpp"
#import "EditorRenderer.hpp"
#import <objc/runtime.h>

NSNotificationName const EditorServiceDidChangeCompositionNotification = @"EditorViewModelDidChangeCompositionNotification";
NSString * const EditorServiceCompositionKey = @"composition";
NSString * const EditorServiceVideoCompositionKey = @"videoComposition";

__attribute__((objc_direct_members))
@interface EditorService ()
@property (retain, readonly, nonatomic) dispatch_queue_t queue;
@property (retain, readonly, nonatomic) SVVideoProject *videoProject;
@property (copy, readonly, nonatomic) NSSet<NSUserActivity *> *userActivities;
@property (copy, nonatomic, getter=queue_composition, setter=queue_setComposition:) AVComposition *queue_composition;
@property (copy, nonatomic, getter=queue_videoComposition, setter=queue_setVideoComposition:) AVVideoComposition *queue_videoComposition;
@end

@implementation EditorService

@synthesize queue_composition = _queue_composition;

+ (CMPersistentTrackID)mainVideoTrackID {
    return 1 << 0;
}

- (instancetype)initWithVideoProject:(SVVideoProject *)videoProject {
    if (self = [super init]) {
        _videoProject = [videoProject retain];
        [self commonInit_EditorViewModel];
    }
    
    return self;
}

- (instancetype)initWithUserActivities:(NSSet<NSUserActivity *> *)userActivities {
    if (self = [super init]) {
        _userActivities = [userActivities copy];
        [self commonInit_EditorViewModel];
    }
    
    return self;
}

- (void)dealloc {
    if (_queue) {
        dispatch_release(_queue);
    }
    
    [_videoProject release];
    [_userActivities release];
    [_queue_composition release];
    [super dealloc];
}

- (void)commonInit_EditorViewModel __attribute__((objc_direct)) {
    dispatch_queue_attr_t attr = dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, QOS_CLASS_USER_INITIATED, QOS_MIN_RELATIVE_PRIORITY);
    dispatch_queue_t queue = dispatch_queue_create("EditorViewModel", attr);
    _queue = queue;
}

- (void)initializeWithProgressHandler:(void (^)(NSProgress * _Nonnull progress))progressHandler
                    completionHandler:(void (^)(AVComposition * _Nullable composition, AVVideoComposition * _Nullable videoComposition, NSError * _Nullable error))completionHandler {
    dispatch_async(self.queue, ^{
        [self queue_videoProjectWithCompletionHandler:^(SVVideoProject * _Nullable videoProject, NSError * _Nullable error) {
            if (error) {
                completionHandler(nil, nil, error);
                return;
            }
            
            [self queue_mutableCompositionFromVideoProject:videoProject completionHandler:^(AVMutableComposition * _Nullable mutableComposition, NSError * _Nullable error) {
                [self queue_appendVideosToMainVideoTrackFromVideoProject:videoProject
                                                      mutableComposition:mutableComposition
                                                           createFootage:NO
                                                         progressHandler:progressHandler
                                                       completionHandler:^(AVComposition * _Nullable composition, NSError * _Nullable error) {
                    
                    [EditorRenderer videoCompositionWithComposition:composition completionHandler:^(AVVideoComposition * _Nullable videoComposition, NSError * _Nullable error) {
                        
                        dispatch_async(self.queue, ^{
                            self.queue_composition = composition;
                            self.queue_videoComposition = videoComposition;
                            [self queue_postCompositionDidChangeNotification];
                            
                            completionHandler(self.queue_composition, self.queue_videoComposition, error);
                        });
                    }];
                }];
            }];
        }];
    });
}

- (void)appendVideosToMainVideoTrackFromPickerResults:(NSArray<PHPickerResult *> *)pickerResults 
                                      progressHandler:(void (^)(NSProgress * _Nonnull progress))progressHandler
                                    completionHandler:(void (^)(AVComposition * _Nullable composition, AVVideoComposition * _Nullable videoComposition, NSError * _Nullable error))completionHandler {
    dispatch_async(self.queue, ^{
        AVComposition * _Nullable composition = self.queue_composition;
        
        if (!composition) {
            completionHandler(nil, nil, [NSError errorWithDomain:SurfVideoErrorDomain code:SurfVideoNotInitializedError userInfo:nil]);
            return;
        }
        
        AVMutableComposition *mutableComposition = [composition mutableCopy];
        
        [self queue_appendVideosToMainVideoTrackFromPickerResults:pickerResults
                                               mutableComposition:mutableComposition
                                                    createFootage:YES
                                                  progressHandler:progressHandler
                                                completionHandler:^(AVMutableComposition * _Nullable mutableComposition, NSError * _Nullable error) {
            [EditorRenderer videoCompositionWithComposition:mutableComposition completionHandler:^(AVVideoComposition * _Nullable videoComposition, NSError * _Nullable error) {
                
                dispatch_async(self.queue, ^{
                    self.queue_composition = mutableComposition;
                    self.queue_videoComposition = videoComposition;
                    [self queue_postCompositionDidChangeNotification];
                    
                    completionHandler(self.queue_composition, self.queue_videoComposition, error);
                });
            }];
        }];
        
        [mutableComposition release];
    });
}

- (void)removeTrackSegment:(AVCompositionTrackSegment *)trackSegment
                 atTrackID:(CMPersistentTrackID)trackID
         completionHandler:(void (^)(AVComposition * _Nullable, AVVideoComposition * _Nullable videoComposition, NSError * _Nullable))completionHandler {
    dispatch_async(self.queue, ^{
        AVMutableComposition *composition = [self.queue_composition mutableCopy];
        
        AVMutableCompositionTrack * _Nullable track = [composition trackWithTrackID:trackID];
        if (!track) {
            [composition release];
            completionHandler(nil, nil, [NSError errorWithDomain:SurfVideoErrorDomain code:SurfVideoNoTrackFoundError userInfo:nil]);
            return;
        }
        
        NSArray<AVCompositionTrackSegment *> *oldSegments = track.segments;
        NSUInteger index = [oldSegments indexOfObject:trackSegment];
        [track removeTimeRange:trackSegment.timeMapping.target];
        
        SVVideoProject *cd_videoProject = self.videoProject;
        
        [cd_videoProject.managedObjectContext performBlock:^{
            SVVideoTrack *cd_mainVideoVtrack = cd_videoProject.mainVideoTrack;
            int64_t count = cd_mainVideoVtrack.videoClipsCount;
            
            assert(count == oldSegments.count);
            SVVideoClip *videoClip = [cd_mainVideoVtrack.videoClips objectAtIndex:index];
            [cd_videoProject.managedObjectContext deleteObject:videoClip];
            
            NSError * _Nullable error = nil;
            [cd_videoProject.managedObjectContext save:&error];
            
            if (error) {
                completionHandler(nil, nil, error);
                return;
            }
            
            [EditorRenderer videoCompositionWithComposition:composition completionHandler:^(AVVideoComposition * _Nullable videoComposition, NSError * _Nullable error) {
                
                dispatch_async(self.queue, ^{
                    self.queue_composition = composition;
                    self.queue_videoComposition = videoComposition;
                    [self queue_postCompositionDidChangeNotification];
                    
                    completionHandler(self.queue_composition, self.queue_videoComposition, error);
                });
            }];
        }];
        
        self.queue_composition = composition;
        [composition release];
    });
}

- (void)queue_videoProjectWithCompletionHandler:(void (^)(SVVideoProject * _Nullable videoProject, NSError * _Nullable error))completionHandler __attribute__((objc_direct)) {
    if (_videoProject) {
        completionHandler(_videoProject, nil);
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
                [_videoProject release];
                _videoProject = [videoProject retain];
                completionHandler(videoProject, nil);
            });
        }];
    }];
}

- (void)queue_mutableCompositionFromVideoProject:(SVVideoProject *)videoProject 
                               completionHandler:(void (^)(AVMutableComposition * _Nullable mutableComposition, NSError * _Nullable error))completionHandler __attribute__((objc_direct)) {
    AVMutableComposition *composition = [AVMutableComposition composition];
    composition.naturalSize = CGSizeMake(1280.f, 720.f);
    [composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:EditorService.mainVideoTrackID];
    
    completionHandler(composition, nil);
}

- (void)queue_appendVideosToMainVideoTrackFromVideoProject:(SVVideoProject *)videoProject
                                        mutableComposition:(AVMutableComposition *)mutableComposition
                                             createFootage:(BOOL)createFootage
                                           progressHandler:(void (^)(NSProgress *progress))progressHandler
                                         completionHandler:(void (^)(AVComposition * _Nullable composition, NSError * _Nullable error))completionHandler  __attribute__((objc_direct)) {
    NSManagedObjectContext * _Nullable context = videoProject.managedObjectContext;
    if (!context) {
        completionHandler(nil, [NSError errorWithDomain:SurfVideoErrorDomain code:SurfVideoNoManagedObjectContextError userInfo:nil]);
        return;
    }
    
    [context performBlock:^{
        auto assetIdentifiers = [NSMutableArray<NSString *> new];
        for (SVVideoClip *videoClip in videoProject.mainVideoTrack.videoClips) {
            __kindof SVFootage *footage = videoClip.footage;
            
            if ([footage isKindOfClass:SVPHAssetFootage.class]) {
                auto phAssetFootage = static_cast<SVPHAssetFootage *>(footage);
                NSString *assetIdentifier = phAssetFootage.assetIdentifier;
                [assetIdentifiers addObject:assetIdentifier];
            }
        }
        
        dispatch_async(self.queue, ^{
            [self queue_appendVideosToMainVideoTrackFromAssetIdentifiers:assetIdentifiers
                                                      mutableComposition:mutableComposition
                                                           createFootage:createFootage
                                                         progressHandler:progressHandler
                                                       completionHandler:completionHandler];
        });
        
        [assetIdentifiers release];
    }];
}

- (void)queue_appendVideosToMainVideoTrackFromAssetIdentifiers:(NSArray<NSString *> *)assetIdentifiers
                                            mutableComposition:(AVMutableComposition *)mutableComposition
                                                 createFootage:(BOOL)createFootage
                                               progressHandler:(void (^)(NSProgress *progress))progressHandler
                                             completionHandler:(void (^)(AVMutableComposition * _Nullable mutableComposition, NSError * _Nullable error))completionHandler __attribute__((objc_direct)) {
    SVVideoProject * _Nullable videoProject = self.videoProject;
    
    AVMutableCompositionTrack *mainVideoTrack = [mutableComposition trackWithTrackID:EditorService.mainVideoTrackID];
    assert(mainVideoTrack);
    
    PHImageManager *imageManager = PHImageManager.defaultManager;
    PHVideoRequestOptions *videoRequestOptions = [PHVideoRequestOptions new];
    videoRequestOptions.deliveryMode = PHVideoRequestOptionsDeliveryModeHighQualityFormat;
    videoRequestOptions.networkAccessAllowed = YES;
    
    NSProgress *progress = [imageManager sv_requestAVAssetsForAssetIdentifiers:assetIdentifiers options:videoRequestOptions partialResultHandler:^(AVAsset * _Nullable avAsset, AVAudioMix * _Nullable avAuioMix, NSDictionary * _Nullable info, PHAsset * _Nonnull asset, BOOL *stop, BOOL isEnd) {
        if (static_cast<NSNumber *>(info[PHImageCancelledKey]).boolValue) {
            *stop = YES;
            dispatch_async(self.queue, ^{
                completionHandler(nil, [NSError errorWithDomain:SurfVideoErrorDomain code:SurfVideoUserCancelledError userInfo:nil]);
            });
            return;
        }
        
        if (auto error = static_cast<NSError *>(info[PHImageErrorKey])) {
            *stop = YES;
            dispatch_async(self.queue, ^{
                completionHandler(nil, error);
            });
            return;
        }
        
        //
        
        for (AVAssetTrack *track in avAsset.tracks) {
            if ([track.mediaType isEqualToString:AVMediaTypeVideo]) {
                NSUInteger oldCount = mainVideoTrack.segments.count;
                
                NSError * _Nullable error = nil;
                [mainVideoTrack insertTimeRange:track.timeRange ofTrack:track atTime:mainVideoTrack.timeRange.duration error:&error];
                
                if (error) {
                    *stop = YES;
                    dispatch_async(self.queue, ^{
                        completionHandler(nil, error);
                    });
                    return;
                }
                
                if (createFootage) {
                    if (NSManagedObjectContext *context = videoProject.managedObjectContext) {
                        [context performBlock:^{
                            SVVideoTrack *videoTrack = videoProject.mainVideoTrack;
                            assert(videoTrack.videoClipsCount == oldCount);
                            
                            SVVideoClip *videoClip = [[SVVideoClip alloc] initWithContext:context];
                            SVPHAssetFootage *footage = [[SVPHAssetFootage alloc] initWithContext:context];
                            footage.assetIdentifier = asset.localIdentifier;
                            videoClip.footage = footage;
                            [footage release];
                            
                            [videoTrack insertObject:videoClip inVideoClipsAtIndex:oldCount];
                            [videoClip release];
                            
                            NSError * _Nullable error = nil;
                            [context save:&error];
                            assert(!error);
                        }];
                    }
                }
                
                break;
            }
        }
        
        if (isEnd) {
            *stop = YES;
            dispatch_async(self.queue, ^{
                completionHandler(mutableComposition, nil);
            });
            return;
        }
    }];
    
    progressHandler(progress);
    [videoRequestOptions release];
}

- (void)queue_appendVideosToMainVideoTrackFromPickerResults:(NSArray<PHPickerResult *> *)pickerResults
                                         mutableComposition:(AVMutableComposition *)mutableComposition
                                              createFootage:(BOOL)createFootage
                                            progressHandler:(void (^)(NSProgress *progress))progressHandler
                                          completionHandler:(void (^)(AVMutableComposition * _Nullable mutableComposition, NSError * _Nullable error))completionHandler  __attribute__((objc_direct)) {
    auto assetIdentifiers = [NSMutableArray<NSString *> new];
    
    for (PHPickerResult *result in pickerResults) {
        NSString *assetIdentifier = result.assetIdentifier;
        
        [assetIdentifiers addObject:assetIdentifier];
    }
    
    [self queue_appendVideosToMainVideoTrackFromAssetIdentifiers:assetIdentifiers
                                              mutableComposition:mutableComposition
                                                   createFootage:createFootage
                                                 progressHandler:progressHandler
                                               completionHandler:completionHandler];
    [assetIdentifiers release];
}

- (void)queue_postCompositionDidChangeNotification __attribute__((objc_direct)) {
    [NSNotificationCenter.defaultCenter postNotificationName:EditorServiceDidChangeCompositionNotification
                                                      object:self 
                                                    userInfo:@{
        EditorServiceCompositionKey: self.queue_composition,
        EditorServiceVideoCompositionKey: self.queue_videoComposition
    }];
}

@end
