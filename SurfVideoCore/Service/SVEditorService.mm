//
//  SVEditorService.mm
//  SurfVideo
//
//  Created by Jinwoo Kim on 12/15/23.
//

#import <SurfVideoCore/SVEditorService.hpp>
#import <SurfVideoCore/SVProjectsManager.hpp>
#import <SurfVideoCore/constants.hpp>
#import <objc/runtime.h>
#import <Photos/Photos.h>
#import <SurfVideoCore/SVEditorService+Private.hpp>
#import <SurfVideoCore/NSManagedObjectContext+CheckThread.hpp>

NSNotificationName const EditorServiceCompositionDidChangeNotification = @"EditorServiceCompositionDidChangeNotification";
NSString * const EditorServiceCompositionKey = @"composition";
NSString * const EditorServiceCompositionIDsKey = @"compositionIDs";
NSString * const EditorServiceVideoCompositionKey = @"videoComposition";
NSString * const EditorServiceRenderElementsKey = @"renderElements";
NSString * const EditorServiceTrackSegmentNamesByCompositionIDKey = @"trackSegmentNamesByCompositionID";

__attribute__((objc_direct_members))
@interface SVEditorService ()
@end

@implementation SVEditorService

- (CMPersistentTrackID)mainVideoTrackID {
    return 1 << 0;
}

- (CMPersistentTrackID)audioTrackID {
    return 1 << 1;
}

- (instancetype)initWithVideoProject:(SVVideoProject *)videoProject {
    if (self = [super init]) {
        _queue_videoProject = [videoProject retain];
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
    if (_queue_1) {
        dispatch_release(_queue_1);
    }
    
    if (_queue_2) {
        dispatch_release(_queue_2);
    }
    
    [_queue_videoProject release];
    [_userActivities release];
    [_queue_composition release];
    [_queue_videoComposition release];
    [_queue_renderElements release];
    [_queue_trackSegmentNamesByCompositionID release];
    [_queue_compositionIDs release];
    [super dealloc];
}

- (void)commonInit_EditorViewModel __attribute__((objc_direct)) {
    dispatch_queue_attr_t attr = dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, QOS_CLASS_USER_INITIATED, QOS_MIN_RELATIVE_PRIORITY);
    dispatch_queue_t queue_1 = dispatch_queue_create("EditorViewModel_1", attr);
    dispatch_queue_t queue_2 = dispatch_queue_create("EditorViewModel_2", attr);
    _queue_1 = queue_1;
    _queue_2 = queue_2;
}

- (void)initializeWithProgressHandler:(void (^)(NSProgress * _Nonnull progress))progressHandler
                    completionHandler:(EditorServiceCompletionHandler)completionHandler {
    dispatch_async(self.queue_1, ^{
        dispatch_suspend(self.queue_1);
        
        [self queue_videoProjectWithCompletionHandler:^(SVVideoProject * _Nullable videoProject, NSError * _Nullable error) {
            if (error) {
                completionHandler(nil, nil, nil, nil, nil, error);
                return;
            }
            
            [videoProject.managedObjectContext sv_performBlock:^{
                [self contextQueue_mutableCompositionFromVideoProject:videoProject progressHandler:progressHandler completionHandler:^(AVMutableComposition * _Nullable mutableComposition, NSDictionary<NSNumber *, NSArray<NSUUID *> *> * _Nullable compositionIDs, NSDictionary<NSUUID *, NSString *> * _Nullable trackSegmentNamesByCompositionID, NSError * _Nullable error) {
                    [videoProject.managedObjectContext sv_performBlock:^{
                        NSArray<__kindof SVEditorRenderElement *> *renderElements = [self contextQueue_renderElementsFromVideoProject:videoProject];
                        
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
            }];
        }];
    });
}

- (void)compositionWithCompletionHandler:(void (^)(AVComposition * _Nullable, AVVideoComposition * _Nullable, NSArray<__kindof SVEditorRenderElement *> * _Nullable))completionHandler {
    dispatch_async(self.queue_1, ^{
        completionHandler(self.queue_composition, self.queue_videoComposition, self.queue_renderElements);
    });
}

- (NSProgress *)exportWithQuality:(EditorServiceExportQuality)quality completionHandler:(void (^)(NSError * _Nullable error))completionHandler {
    NSProgress *progress = [self exportToURLWithQuality:quality completionHandler:^(NSURL * _Nullable outputURL, NSError * _Nullable error) {
        if (error) {
            completionHandler(error);
            return;
        }
        
        [PHPhotoLibrary.sharedPhotoLibrary performChanges:^{
            [PHAssetChangeRequest creationRequestForAssetFromVideoAtFileURL:outputURL];
        } 
                                        completionHandler:^(BOOL success, NSError * _Nullable error) {
            if (error) {
                completionHandler(error);
                return;
            }
            
            NSError *_error = nil;
            [NSFileManager.defaultManager removeItemAtURL:outputURL error:&_error];
            
            if (_error) {
                completionHandler(_error);
                return;
            }
            
            completionHandler(nil);
        }];
    }];
    
    return progress;
}

@end
