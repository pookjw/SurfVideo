//
//  EditorViewModel.cpp
//  SurfVideo
//
//  Created by Jinwoo Kim on 12/2/23.
//

#import "EditorViewModel.hpp"
#import "constants.hpp"
#import "SVProjectsManager.hpp"

EditorViewModel::EditorViewModel(NSSet<NSUserActivity *> *userActivities) : _userActivites([userActivities retain]) {
    dispatch_queue_attr_t attr = dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, QOS_CLASS_USER_INITIATED, QOS_MIN_RELATIVE_PRIORITY);
    dispatch_queue_t queue = dispatch_queue_create("EditorViewModel", attr);
    if (_queue) {
        dispatch_release(_queue);
    }
    _queue = queue;
}

EditorViewModel::~EditorViewModel() {
    dispatch_release(_queue);
    [_userActivites release];
}

void EditorViewModel::initialize(std::shared_ptr<EditorViewModel> ref, void (^completionHandler)(NSError * _Nullable error)) {
    dispatch_async(ref.get()->_queue, ^{
        NSURL * _Nullable uriRepresentation = nil;
        
        for (NSUserActivity *userActivity in ref.get()->_userActivites) {
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
        
        __block SVVideoProject * _Nullable videoProject = nil;
        __block NSError * _Nullable error = nil;
        
        dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
        SVProjectsManager::getInstance().context(^(NSManagedObjectContext * _Nullable context, NSError * _Nullable _error) {
            if (error) {
                error = [_error retain];
                dispatch_semaphore_signal(semaphore);
            } else {
                [context performBlock:^{
                    NSManagedObjectID *objectID = [context.persistentStoreCoordinator managedObjectIDForURIRepresentation:uriRepresentation];
                    videoProject = [[context objectWithID:objectID] retain];
                    dispatch_semaphore_signal(semaphore);
                }];
            }
        });
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
        dispatch_release(semaphore);
        
        [videoProject autorelease];
        [error autorelease];
        
        //
        
        if (error) {
            completionHandler(error);
            return;
        }
        
        NSLog(@"%@", videoProject);
        completionHandler(nil);
    });
}
