//
//  EditorViewModel.cpp
//  SurfVideo
//
//  Created by Jinwoo Kim on 12/2/23.
//

#import "EditorViewModel.hpp"
#import "constants.hpp"
#import "SVProjectsManager.hpp"
#import <string>
#import <array>
#import <algorithm>

EditorViewModel::EditorViewModel(std::variant<NSSet<NSUserActivity *> *, SVVideoProject *> initialData) {
    dispatch_queue_attr_t attr = dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, QOS_CLASS_USER_INITIATED, QOS_MIN_RELATIVE_PRIORITY);
    dispatch_queue_t queue = dispatch_queue_create("EditorViewModel", attr);
    _queue = queue;
    
    if (std::holds_alternative<NSSet<NSUserActivity *> *>(initialData)) {
        [std::get<NSSet<NSUserActivity *> *>(initialData) retain];
    } else if (std::holds_alternative<SVVideoProject *>(initialData)) {
        [std::get<SVVideoProject *>(initialData) retain];
    }
    
    _initialData = initialData;
}

EditorViewModel::~EditorViewModel() {
    dispatch_release(_queue);
    if (std::holds_alternative<NSSet<NSUserActivity *> *>(_initialData)) {
        [std::get<NSSet<NSUserActivity *> *>(_initialData) release];
    } else if (std::holds_alternative<SVVideoProject *>(_initialData)) {
        [std::get<SVVideoProject *>(_initialData) release];
    }
    [_videoProject release];
    [_composition release];
}

void EditorViewModel::initialize(std::shared_ptr<EditorViewModel> ref, void (^completionHandler)(NSError * _Nullable error)) {
    dispatch_async(ref.get()->_queue, ^{
        SVVideoProject * _Nullable videoProject = nil;
        
        if (std::holds_alternative<NSSet<NSUserActivity *> *>(ref.get()->_initialData)) {
            NSSet<NSUserActivity *> *userActivities = std::get<NSSet<NSUserActivity *> *>(ref.get()->_initialData);
            
            NSURL * _Nullable uriRepresentation = nil;
            
            for (NSUserActivity *userActivity in userActivities) {
                if ([userActivity.activityType isEqualToString:kEditorWindowSceneUserActivityType]) {
                    uriRepresentation = userActivity.userInfo[EditorWindowUserActivityVideoProjectURIRepresentationKey];
                    break;
                }
            }
            
            if (!uriRepresentation) {
                completionHandler([NSError errorWithDomain:SurfVideoErrorDomain code:SurfVideoNoURIRepresentationError userInfo:nil]);
                return;
            }
            
            //
            
            __block SVVideoProject * _Nullable _videoProject = nil;
            __block NSError * _Nullable error = nil;
            
            dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
            SVProjectsManager::getInstance().context(^(NSManagedObjectContext * _Nullable context, NSError * _Nullable _error) {
                if (error) {
                    error = [_error retain];
                    dispatch_semaphore_signal(semaphore);
                } else {
                    [context performBlock:^{
                        NSManagedObjectID *objectID = [context.persistentStoreCoordinator managedObjectIDForURIRepresentation:uriRepresentation];
                        _videoProject = [[context objectWithID:objectID] retain];
                        dispatch_semaphore_signal(semaphore);
                    }];
                }
            });
            dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
            dispatch_release(semaphore);
            
            [_videoProject autorelease];
            [error autorelease];
            
            if (error) {
                completionHandler(error);
                return;
            }
            
            videoProject = _videoProject;
        } else if (std::holds_alternative<SVVideoProject *>(ref.get()->_initialData)) {
            videoProject = std::get<SVVideoProject *>(ref.get()->_initialData);
        }
        
        //
        
        ref.get()->_videoProject = [videoProject retain];
        ref.get()->setupComposition();
        completionHandler(nil);
    });
}

void EditorViewModel::setupComposition() {
    AVMutableComposition *composition = [AVMutableComposition composition];
    composition.naturalSize = CGSizeMake(1280.f, 720.f);
    
    AVMutableCompositionTrack *firstTrack = [composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    
    const std::array<std::string, 6> sampleFileNames {"0", "1", "2", "3", "4", "5"};
    CMTime time = kCMTimeZero;
    std::for_each(sampleFileNames.cbegin(), sampleFileNames.cend(), [firstTrack, &time](const std::string fileName) {
        NSAutoreleasePool *pool = [NSAutoreleasePool new];
        
        NSURL *url = [NSBundle.mainBundle URLForResource:[NSString stringWithCString:fileName.data() encoding:NSUTF8StringEncoding] withExtension:@"mp4"];
        AVAsset *asset = [AVAsset assetWithURL:url];
        
//        CMTime nextClipStart = kCMTimeZero;
//        for (AVAssetTrack *track in asset.tracks) {
//            CMTimeRange timeRange = CMTimeMake(nextClipStart., <#int32_t timescale#>)
//            [firstTrack insertTimeRange:<#(CMTimeRange)#> ofTrack:<#(nonnull AVAssetTrack *)#> atTime:nextClipStart error:<#(NSError * _Nullable * _Nullable)#>]
//        }
        
        AVAssetTrack *track = asset.tracks.firstObject;
        NSError * _Nullable error = nil;
        [firstTrack insertTimeRange:track.timeRange ofTrack:track atTime:time error:&error];
        assert(!error);
        time = CMTimeAdd(time, track.timeRange.duration);
        
        [pool release];
    });
    
    NSLog(@"%@", firstTrack);
    
    [_composition release];
    _composition = [composition retain];
}
