//
//  EditorViewModel.mm
//  SurfVideo
//
//  Created by Jinwoo Kim on 12/15/23.
//

#import "EditorViewModel.hpp"
#import "constants.hpp"
#import "SVProjectsManager.hpp"
#import "SVPHAssetFootage.hpp"
#import "PHImageManager+RequestAVAssets.hpp"

__attribute__((objc_direct_members))
@interface EditorViewModel ()
@property (retain, readonly, nonatomic) dispatch_queue_t queue;
@property (retain, readonly, nonatomic) SVVideoProject *videoProject;
@property (copy, readonly, nonatomic) NSSet<NSUserActivity *> *userActivities;
@property (copy, readonly, nonatomic) AVComposition *composition;
@end

@implementation EditorViewModel

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

- (CMPersistentTrackID)mainVideoTrackID {
    return 1 << 0;
}

- (void)initializeWithProgressHandler:(void (^)(NSProgress * _Nonnull progress))progressHandler
                    completionHandler:(void (^)(AVComposition * _Nullable composition, NSError * _Nullable error))completionHandler {
    dispatch_async(_queue, ^{
        [self unsafe_videoProjectWithCompletionHandler:^(SVVideoProject * _Nullable videoProject, NSError * _Nullable error) {
            if (error) {
                completionHandler(nil, error);
                return;
            }
            
            [self unsafe_compositionFromVideoProject:videoProject completionHandler:^(AVComposition * _Nullable composition, NSError * _Nullable error) {
                [self unsafe_appendVideosToMainVideoTrackFromVideoProject:videoProject
                                                              composition:composition
                                                          progressHandler:progressHandler
                                                        completionHandler:^(AVComposition * _Nullable composition, NSError * _Nullable error) {
                    [_composition release];
                    _composition = [composition retain];
                    
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
        if (!_composition) {
            completionHandler(nil, [NSError errorWithDomain:SurfVideoErrorDomain code:SurfVideoNotInitializedError userInfo:nil]);
            return;
        }
        
        [self unsafe_appendVideosToMainVideoTrackFromPickerResults:pickerResults
                                                       composition:_composition
                                                   progressHandler:progressHandler
                                                 completionHandler:completionHandler];
    });
}

- (void)unsafe_videoProjectWithCompletionHandler:(void (^)(SVVideoProject * _Nullable videoProject, NSError * _Nullable error))completionHandler __attribute__((objc_direct)) {
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
    [composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:self.mainVideoTrackID];
    
    completionHandler([[composition copy] autorelease], nil);
}

- (void)unsafe_appendVideosToMainVideoTrackFromVideoProject:(SVVideoProject *)videoProject
                                                composition:(AVComposition *)composition
                                            progressHandler:(void (^)(NSProgress *progress))progressHandler
                                          completionHandler:(void (^)(AVComposition * _Nullable composition, NSError * _Nullable error))completionHandler  __attribute__((objc_direct)) {
    NSManagedObjectContext * _Nullable context = videoProject.managedObjectContext;
    if (!context) {
        completionHandler(nil, [NSError errorWithDomain:SurfVideoErrorDomain code:SurfVideoNoManagedObjectContextError userInfo:nil]);
        return;
    }
    
    [context performBlock:^{
        NSOrderedSet<SVFootage *> *footages = videoProject.footages;
        NSMutableArray<NSString *> *assetIdentifiers = [NSMutableArray<NSString *> new];
        for (SVFootage *footage in footages) {
            if ([footage isKindOfClass:SVPHAssetFootage.class]) {
                auto phAssetFootage = static_cast<SVPHAssetFootage *>(footage);
                [assetIdentifiers addObject:phAssetFootage.assetIdentifier];
            }
        }
        
        dispatch_async(_queue, ^{
            [self unsafe_appendVideosToMainVideoTrackFromAssetIdentifiers:assetIdentifiers
                                                              composition:composition
                                                          progressHandler:progressHandler
                                                        completionHandler:completionHandler];
        });
        [assetIdentifiers release];
    }];
}

- (void)unsafe_appendVideosToMainVideoTrackFromAssetIdentifiers:(NSArray<NSString *> *)assetIdentifiers
                                                    composition:(AVComposition *)composition
                                                progressHandler:(void (^)(NSProgress *progress))progressHandler
                                              completionHandler:(void (^)(AVComposition * _Nullable composition, NSError * _Nullable error))completionHandler  __attribute__((objc_direct)) {
    PHFetchOptions *fetchOptions = [PHFetchOptions new];
    fetchOptions.includeHiddenAssets = YES;
    PHFetchResult<PHAsset *> *fetchResult = [PHAsset fetchAssetsWithLocalIdentifiers:assetIdentifiers options:fetchOptions];
    [fetchOptions release];
    
    if (fetchResult.count == 0) {
        completionHandler(composition, nil);
        return;
    }
    
    [self unsafe_appendVideosToMainVideoTrackFromFetchResult:fetchResult
                                                 composition:composition
                                             progressHandler:progressHandler
                                           completionHandler:completionHandler];
}

- (void)unsafe_appendVideosToMainVideoTrackFromFetchResult:(PHFetchResult<PHAsset *> *)fetchResult
                                               composition:(AVComposition *)composition
                                           progressHandler:(void (^)(NSProgress *progress))progressHandler
                                         completionHandler:(void (^)(AVComposition * _Nullable composition, NSError * _Nullable error))completionHandler  __attribute__((objc_direct)) {
    AVMutableComposition *mutableComposition = [composition mutableCopy];
    AVMutableCompositionTrack *mainVideoTrack = [mutableComposition trackWithTrackID:self.mainVideoTrackID];
    
    PHImageManager *imageManager = PHImageManager.defaultManager;
    PHVideoRequestOptions *videoRequestOptions = [PHVideoRequestOptions new];
    videoRequestOptions.deliveryMode = PHVideoRequestOptionsDeliveryModeHighQualityFormat;
    videoRequestOptions.networkAccessAllowed = YES;
    
    NSProgress *progress = [imageManager sv_requestAVAssetsForFetchResult:fetchResult options:videoRequestOptions partialResultHandler:^(AVAsset * _Nullable avAsset, AVAudioMix * _Nullable avAuioMix, NSDictionary * _Nullable info, PHAsset * _Nonnull asset, BOOL *stop, BOOL isEnd) {
        if (static_cast<NSNumber *>(info[PHImageCancelledKey]).boolValue) {
            *stop = YES;
            dispatch_async(_queue, ^{
                completionHandler(nil, [NSError errorWithDomain:SurfVideoErrorDomain code:SurfVideoUserCancelledError userInfo:nil]);
            });
            return;
        }
        
        if (auto error = static_cast<NSError *>(info[PHImageErrorKey])) {
            *stop = YES;
            dispatch_async(_queue, ^{
                completionHandler(nil, error);
            });
            return;
        }
        
        //
        
        for (AVAssetTrack *track in avAsset.tracks) {
            if ([track.mediaType isEqualToString:AVMediaTypeVideo]) {
                NSError * _Nullable error = nil;
                [mainVideoTrack insertTimeRange:track.timeRange ofTrack:track atTime:mainVideoTrack.timeRange.duration error:&error];
                
                if (error) {
                    *stop = YES;
                    dispatch_async(_queue, ^{
                        completionHandler(nil, error);
                    });
                    return;
                }
                
                break;
            }
        }
        
        if (isEnd) {
            *stop = YES;
            dispatch_async(_queue, ^{
                completionHandler([[mutableComposition copy] autorelease], nil);
            });
            return;
        }
    }];
    
    progressHandler(progress);
    [mutableComposition release];
    [videoRequestOptions release];
}


- (void)unsafe_appendVideosToMainVideoTrackFromPickerResults:(NSArray<PHPickerResult *> *)pickerResults
                                               composition:(AVComposition *)composition
                                           progressHandler:(void (^)(NSProgress *progress))progressHandler
                                         completionHandler:(void (^)(AVComposition * _Nullable composition, NSError * _Nullable error))completionHandler  __attribute__((objc_direct)) {
    NSMutableArray<NSString *> *assetIdentifiers = [NSMutableArray<NSString *> new];
    for (PHPickerResult *result in pickerResults) {
        [assetIdentifiers addObject:result.assetIdentifier];
    }
    
    [self unsafe_appendVideosToMainVideoTrackFromAssetIdentifiers:assetIdentifiers
                                                      composition:composition
                                                  progressHandler:progressHandler
                                                completionHandler:completionHandler];
    [assetIdentifiers release];
}

@end
