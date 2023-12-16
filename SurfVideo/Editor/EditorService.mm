//
//  EditorService.mm
//  SurfVideo
//
//  Created by Jinwoo Kim on 12/15/23.
//

#import "EditorService.hpp"
#import "constants.hpp"
#import "SVProjectsManager.hpp"
#import "SVPHAssetFootage.hpp"
#import "PHImageManager+RequestAVAssets.hpp"
#import <objc/runtime.h>

NSNotificationName const EditorServiceDidChangeCompositionNotification = @"EditorViewModelDidChangeCompositionNotification";
NSString * const EditorServiceDidChangeCompositionKey = @"composition";

__attribute__((objc_direct_members))
@interface EditorService ()
@property (retain, readonly, nonatomic) dispatch_queue_t queue;
@property (retain, readonly, nonatomic) SVVideoProject *videoProject;
@property (copy, readonly, nonatomic) NSSet<NSUserActivity *> *userActivities;
@property (copy, nonatomic, getter=unsafe_composition, setter=unsafe_setComposition:) AVComposition *composition;
@end

@implementation EditorService
@synthesize composition = _composition;

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
    [_composition release];
    [super dealloc];
}

- (void)commonInit_EditorViewModel __attribute__((objc_direct)) {
    dispatch_queue_attr_t attr = dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, QOS_CLASS_USER_INITIATED, QOS_MIN_RELATIVE_PRIORITY);
    dispatch_queue_t queue = dispatch_queue_create("EditorViewModel", attr);
    _queue = queue;
}

- (void)initializeWithProgressHandler:(void (^)(NSProgress * _Nonnull progress))progressHandler
                    completionHandler:(void (^)(AVComposition * _Nullable composition, NSError * _Nullable error))completionHandler {
    dispatch_async(_queue, ^{
        [self unsafe_videoProjectWithCompletionHandler:^(SVVideoProject * _Nullable videoProject, NSError * _Nullable error) {
            if (error) {
                completionHandler(nil, error);
                NS_VOIDRETURN;
            }
            
            [self unsafe_compositionFromVideoProject:videoProject completionHandler:^(AVComposition * _Nullable composition, NSError * _Nullable error) {
                [self unsafe_appendVideosToMainVideoTrackFromVideoProject:videoProject
                                                              composition:composition
                                                            createFootage:NO
                                                          progressHandler:progressHandler
                                                        completionHandler:^(AVComposition * _Nullable composition, NSError * _Nullable error) {
                    self.composition = composition;
                    completionHandler(composition, error);
                }];
            }];
        }];
    });
}

- (void)appendVideosToMainVideoTrackFromPickerResults:(NSArray<PHPickerResult *> *)pickerResults 
                                      progressHandler:(void (^)(NSProgress * _Nonnull progress))progressHandler
                                    completionHandler:(void (^)(AVComposition * _Nullable composition, NSError * _Nullable error))completionHandler {
    dispatch_async(_queue, ^{
        if (!self.composition) {
            completionHandler(nil, [NSError errorWithDomain:SurfVideoErrorDomain code:SurfVideoNotInitializedError userInfo:nil]);
            NS_VOIDRETURN;
        }
        
        [self unsafe_appendVideosToMainVideoTrackFromPickerResults:pickerResults
                                                       composition:self.composition
                                                     createFootage:YES
                                                   progressHandler:progressHandler
                                                 completionHandler:^(AVComposition * _Nullable composition, NSError * _Nullable error) {
            self.composition = composition;
            completionHandler(composition, error);
        }];
    });
}

- (void)removeTrackSegment:(AVCompositionTrackSegment *)trackSegment
                 atTrackID:(CMPersistentTrackID)trackID
         completionHandler:(void (^)(AVComposition * _Nullable, NSError * _Nullable))completionHandler {
    dispatch_async(_queue, ^{
        AVMutableComposition *composition = [_composition mutableCopy];
        
        AVMutableCompositionTrack * _Nullable track = [composition trackWithTrackID:trackID];
        if (!track) {
            [composition release];
            completionHandler(nil, [NSError errorWithDomain:SurfVideoErrorDomain code:SurfVideoNoTrackFoundError userInfo:nil]);
            NS_VOIDRETURN;
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
                completionHandler(nil, error);
                NS_VOIDRETURN;
            }
            
            completionHandler([[composition copy] autorelease], nil);
        }];
        
        self.composition = composition;
        [composition release];
    });
}

- (void)unsafe_videoProjectWithCompletionHandler:(void (^)(SVVideoProject * _Nullable videoProject, NSError * _Nullable error))completionHandler __attribute__((objc_direct)) {
    if (_videoProject) {
        completionHandler(_videoProject, nil);
        NS_VOIDRETURN;
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
        NS_VOIDRETURN;
    }
    
    //
    
    SVProjectsManager::getInstance().context(^(NSManagedObjectContext * _Nullable context, NSError * _Nullable error) {
        if (error) {
            completionHandler(nil, error);
        } else {
            [context performBlock:^{
                NSManagedObjectID *objectID = [context.persistentStoreCoordinator managedObjectIDForURIRepresentation:uriRepresentation];
                auto videoProject = static_cast<SVVideoProject *>([context objectWithID:objectID]);
                
                dispatch_async(_queue, ^{
                    [_videoProject release];
                    _videoProject = [videoProject retain];
                    completionHandler(videoProject, nil);
                });
            }];
        }
    });
}

- (void)unsafe_compositionFromVideoProject:(SVVideoProject *)videoProject 
                         completionHandler:(void (^)(AVComposition * _Nullable composition, NSError * _Nullable error))completionHandler __attribute__((objc_direct)) {
    AVMutableComposition *composition = [AVMutableComposition composition];
    composition.naturalSize = CGSizeMake(1280.f, 720.f);
    [composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:EditorService.mainVideoTrackID];
    
    completionHandler([[composition copy] autorelease], nil);
}

- (void)unsafe_appendVideosToMainVideoTrackFromVideoProject:(SVVideoProject *)videoProject
                                                composition:(AVComposition *)composition
                                              createFootage:(BOOL)createFootage
                                            progressHandler:(void (^)(NSProgress *progress))progressHandler
                                          completionHandler:(void (^)(AVComposition * _Nullable composition, NSError * _Nullable error))completionHandler  __attribute__((objc_direct)) {
    NSManagedObjectContext * _Nullable context = videoProject.managedObjectContext;
    if (!context) {
        completionHandler(nil, [NSError errorWithDomain:SurfVideoErrorDomain code:SurfVideoNoManagedObjectContextError userInfo:nil]);
        NS_VOIDRETURN;
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
        
        dispatch_async(_queue, ^{
            [self unsafe_appendVideosToMainVideoTrackFromAssetIdentifiers:assetIdentifiers
                                                              composition:composition
                                                            createFootage:createFootage
                                                          progressHandler:progressHandler
                                                        completionHandler:completionHandler];
        });
        
        [assetIdentifiers release];
    }];
}

- (void)unsafe_appendVideosToMainVideoTrackFromAssetIdentifiers:(NSArray<NSString *> *)assetIdentifiers
                                                    composition:(AVComposition *)composition
                                                  createFootage:(BOOL)createFootage
                                                progressHandler:(void (^)(NSProgress *progress))progressHandler
                                              completionHandler:(void (^)(AVComposition * _Nullable composition, NSError * _Nullable error))completionHandler  __attribute__((objc_direct)) {
    SVVideoProject * _Nullable videoProject = nil;
    if (createFootage) {
        videoProject = self.videoProject;
    }
    
    AVMutableComposition *mutableComposition = [composition mutableCopy];
    AVMutableCompositionTrack *mainVideoTrack = [mutableComposition trackWithTrackID:EditorService.mainVideoTrackID];
    
    PHImageManager *imageManager = PHImageManager.defaultManager;
    PHVideoRequestOptions *videoRequestOptions = [PHVideoRequestOptions new];
    videoRequestOptions.deliveryMode = PHVideoRequestOptionsDeliveryModeHighQualityFormat;
    videoRequestOptions.networkAccessAllowed = YES;
    
    NSProgress *progress = [imageManager sv_requestAVAssetsForAssetIdentifiers:assetIdentifiers options:videoRequestOptions partialResultHandler:^(AVAsset * _Nullable avAsset, AVAudioMix * _Nullable avAuioMix, NSDictionary * _Nullable info, PHAsset * _Nonnull asset, BOOL *stop, BOOL isEnd) {
        if (static_cast<NSNumber *>(info[PHImageCancelledKey]).boolValue) {
            *stop = YES;
            dispatch_async(_queue, ^{
                completionHandler(nil, [NSError errorWithDomain:SurfVideoErrorDomain code:SurfVideoUserCancelledError userInfo:nil]);
            });
            NS_VOIDRETURN;
        }
        
        if (auto error = static_cast<NSError *>(info[PHImageErrorKey])) {
            *stop = YES;
            dispatch_async(_queue, ^{
                completionHandler(nil, error);
            });
            NS_VOIDRETURN;
        }
        
        //
        
        for (AVAssetTrack *track in avAsset.tracks) {
            if ([track.mediaType isEqualToString:AVMediaTypeVideo]) {
                NSError * _Nullable error = nil;
                NSUInteger oldCount = mainVideoTrack.segments.count;
                [mainVideoTrack insertTimeRange:track.timeRange ofTrack:track atTime:mainVideoTrack.timeRange.duration error:&error];
                
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
                
                if (error) {
                    *stop = YES;
                    dispatch_async(_queue, ^{
                        completionHandler(nil, error);
                    });
                    NS_VOIDRETURN;
                }
                
                break;
            }
        }
        
        if (isEnd) {
            *stop = YES;
            dispatch_async(_queue, ^{
                completionHandler([[mutableComposition copy] autorelease], nil);
            });
            NS_VOIDRETURN;
        }
    }];
    
    progressHandler(progress);
    [mutableComposition release];
    [videoRequestOptions release];
}

- (void)unsafe_appendVideosToMainVideoTrackFromPickerResults:(NSArray<PHPickerResult *> *)pickerResults
                                                 composition:(AVComposition *)composition
                                               createFootage:(BOOL)createFootage
                                             progressHandler:(void (^)(NSProgress *progress))progressHandler
                                           completionHandler:(void (^)(AVComposition * _Nullable composition, NSError * _Nullable error))completionHandler  __attribute__((objc_direct)) {
    auto assetIdentifiers = [NSMutableArray<NSString *> new];
    
    for (PHPickerResult *result in pickerResults) {
        NSString *assetIdentifier = result.assetIdentifier;
        
        [assetIdentifiers addObject:assetIdentifier];
    }
    
    [self unsafe_appendVideosToMainVideoTrackFromAssetIdentifiers:assetIdentifiers
                                                      composition:composition
                                                    createFootage:createFootage
                                                  progressHandler:progressHandler
                                                completionHandler:completionHandler];
    [assetIdentifiers release];
}

- (AVComposition *)unsafe_composition {
    return _composition;
}

- (void)unsafe_setComposition:(AVComposition *)composition {
    [_composition release];
    _composition = [composition copy];
    
    NSDictionary * _Nullable userInfo = nil;
    if (composition) {
        userInfo = @{EditorServiceDidChangeCompositionKey: composition};
    } else {
        userInfo = nil;
    }
    
    [NSNotificationCenter.defaultCenter postNotificationName:EditorServiceDidChangeCompositionNotification
                                                      object:self
                                                    userInfo:userInfo];
}

@end
