//
//  EditorViewModel.cpp
//  SurfVideo
//
//  Created by Jinwoo Kim on 12/2/23.
//

#import "EditorViewModel.hpp"
#import "constants.hpp"
#import "SVProjectsManager.hpp"
#import "SVPHAssetFootage.hpp"
#import <Photos/Photos.h>

EditorViewModel::EditorViewModel(std::variant<NSSet<NSUserActivity *> *, SVVideoProject *> videoProjectVariant) {
    dispatch_queue_attr_t attr = dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, QOS_CLASS_USER_INITIATED, QOS_MIN_RELATIVE_PRIORITY);
    dispatch_queue_t queue = dispatch_queue_create("EditorViewModel", attr);
    _queue = queue;
    
    if (std::holds_alternative<NSSet<NSUserActivity *> *>(videoProjectVariant)) {
        [std::get<NSSet<NSUserActivity *> *>(videoProjectVariant) retain];
    } else if (std::holds_alternative<SVVideoProject *>(videoProjectVariant)) {
        [std::get<SVVideoProject *>(videoProjectVariant) retain];
    }
    
    _videoProjectVariant = videoProjectVariant;
}

EditorViewModel::~EditorViewModel() {
    dispatch_release(_queue);
    
    if (std::holds_alternative<NSSet<NSUserActivity *> *>(_videoProjectVariant)) {
        [std::get<NSSet<NSUserActivity *> *>(_videoProjectVariant) release];
    } else if (std::holds_alternative<SVVideoProject *>(_videoProjectVariant)) {
        [std::get<SVVideoProject *>(_videoProjectVariant) release];
    }
}

void EditorViewModel::initialize(std::shared_ptr<EditorViewModel> ref, void (^progressHandler)(NSProgress *progress), void (^completionHandler)(AVMutableComposition * _Nullable composition, NSError * _Nullable error)) {
    dispatch_async(ref.get()->_queue, ^{
        ref.get()->videoProjectFromVarient(ref.get()->_videoProjectVariant, ^(SVVideoProject * _Nullable videoProject, NSError * _Nullable error) {
            if (error) {
                completionHandler(nil, error);
                return;
            }
            
            ref.get()->composition(videoProject, progressHandler, ^(AVMutableComposition * _Nullable composition, NSError * _Nullable error) {
                completionHandler(composition, error);
            });
        });
    });
}

void EditorViewModel::videoProjectFromVarient(std::variant<NSSet<NSUserActivity *> *, SVVideoProject *> videoProjectVariant, void (^completionHandler)(SVVideoProject * _Nullable videoProject, NSError * _Nullable error)) {
    if (std::holds_alternative<NSSet<NSUserActivity *> *>(videoProjectVariant)) {
        NSSet<NSUserActivity *> *userActivities = std::get<NSSet<NSUserActivity *> *>(videoProjectVariant);
        
        NSURL * _Nullable uriRepresentation = nil;
        
        for (NSUserActivity *userActivity in userActivities) {
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
                    completionHandler(videoProject, nil);
                }];
            }
        });
    } else if (std::holds_alternative<SVVideoProject *>(videoProjectVariant)) {
        auto videoProject = std::get<SVVideoProject *>(videoProjectVariant);
        completionHandler(videoProject, nil);
    }
}

void EditorViewModel::composition(SVVideoProject *videoProject, void (^progressHandler)(NSProgress *progress), void (^completionHandler)(AVMutableComposition * _Nullable composition, NSError * _Nullable error)) {
    AVMutableComposition *composition = [AVMutableComposition composition];
    composition.naturalSize = CGSizeMake(1280.f, 720.f);
    
    AVMutableCompositionTrack *firstTrack = [composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    
    NSManagedObjectContext * _Nullable context = videoProject.managedObjectContext;
    if (!context) {
        completionHandler(nil, [NSError errorWithDomain:SurfVideoErrorDomain code:SurfVideoNoManagedObjectContextError userInfo:nil]);
        return;
    }
    
    auto queue = _queue;
    
    [context performBlock:^{
        NSOrderedSet<SVFootage *> *footages = videoProject.footages;
        NSMutableArray<NSString *> *assetIdentifiers = [NSMutableArray<NSString *> new];
        for (SVFootage *footage in footages) {
            if ([footage isKindOfClass:SVPHAssetFootage.class]) {
                auto phAssetFootage = static_cast<SVPHAssetFootage *>(footage);
                [assetIdentifiers addObject:phAssetFootage.assetIdentifier];
            }
        }
        
        dispatch_async(queue, ^{
            PHFetchOptions *fetchOptions = [PHFetchOptions new];
            fetchOptions.includeHiddenAssets = YES;
            PHFetchResult<PHAsset *> *phAssetFetchResult = [PHAsset fetchAssetsWithLocalIdentifiers:assetIdentifiers options:fetchOptions];
            [fetchOptions release];
            
            const NSUInteger count = phAssetFetchResult.count;
            if (count == 0) {
                completionHandler(composition, nil);
                return;
            }
            
            NSProgress *progress = [NSProgress progressWithTotalUnitCount:count * 1000000];
            progressHandler(progress);
            
            PHImageManager *imageManager = PHImageManager.defaultManager;
            PHVideoRequestOptions *videoRequestOptions = [PHVideoRequestOptions new];
            videoRequestOptions.deliveryMode = PHVideoRequestOptionsDeliveryModeHighQualityFormat;
            videoRequestOptions.networkAccessAllowed = YES;
            
            __block CMTime time = kCMTimeZero;
            __block NSUInteger index = 0;
            __block void (^ _Nullable resultHandler)(AVAsset *, AVAudioMix *, NSDictionary *) = nil;
            resultHandler = ^void (AVAsset *__nullable asset, AVAudioMix *__nullable audioMix, NSDictionary *__nullable info) {
                if (progress.isCancelled) {
                    completionHandler(nil, [NSError errorWithDomain:SurfVideoErrorDomain code:SurfVideoUserCancelledError userInfo:nil]);
                    return;
                }
                
                if (index > 0) {
                    AVAssetTrack *track = asset.tracks.firstObject;
                    NSError * _Nullable error = nil;
                    [firstTrack insertTimeRange:track.timeRange ofTrack:track atTime:time error:&error];
                    assert(!error);
                    time = CMTimeAdd(time, track.timeRange.duration);
                    
                    if (count <= index) {
                        completionHandler(composition, nil);
                        return;
                    }
                }
                
                auto copiedVideoRequestOptions = static_cast<PHVideoRequestOptions *>([videoRequestOptions copy]);
                NSProgress *childProgress = [NSProgress progressWithTotalUnitCount:1000000];
                [progress addChild:childProgress withPendingUnitCount:1000000];
                copiedVideoRequestOptions.progressHandler = ^(double progress, NSError * _Nullable error, BOOL * _Nonnull stop, NSDictionary * _Nullable info) {
                    childProgress.completedUnitCount = progress * 1000000.0;
                };
                
                PHImageRequestID requestID = [imageManager requestAVAssetForVideo:phAssetFetchResult[index++] options:copiedVideoRequestOptions resultHandler:resultHandler];
                [copiedVideoRequestOptions release];
                
                progress.cancellationHandler = ^{
                    [imageManager cancelImageRequest:requestID];
                };
            };
            
            resultHandler = [[resultHandler copy] autorelease];
            resultHandler(nil, nil, nil);
            
            [videoRequestOptions release];
        });
        
        [assetIdentifiers release];
    }];
}
