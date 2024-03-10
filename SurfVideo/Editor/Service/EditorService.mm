//
//  EditorService.mm
//  SurfVideo
//
//  Created by Jinwoo Kim on 12/15/23.
//

#import "EditorService.hpp"
#import "SVProjectsManager.hpp"
#import "constants.hpp"
#import <objc/runtime.h>
#import <Photos/Photos.h>
#import "EditorService+Private.hpp"

NSNotificationName const EditorServiceCompositionDidChangeNotification = @"EditorServiceCompositionDidChangeNotification";
NSString * const EditorServiceCompositionKey = @"composition";
NSString * const EditorServiceVideoCompositionKey = @"videoComposition";
NSString * const EditorServiceRenderElementsKey = @"renderElements";
NSString * const EditorServiceTrackSegmentNamesKey = @"trackSegmentNames";

__attribute__((objc_direct_members))
@interface EditorService ()
@end

@implementation EditorService

- (CMPersistentTrackID)mainVideoTrackID {
    return 1 << 0;
}

- (CMPersistentTrackID)audioTrackID {
    return 1 << 1;
}

- (instancetype)initWithVideoProject:(SVVideoProject *)videoProject {
    if (self = [super init]) {
        self.queue_videoProject = videoProject;
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
    
    [_queue_videoProject release];
    [_userActivities release];
    [_queue_composition release];
    [_queue_videoComposition release];
    [_queue_renderElements release];
    [_queue_trackSegmentNames release];
    [super dealloc];
}

- (void)commonInit_EditorViewModel __attribute__((objc_direct)) {
    dispatch_queue_attr_t attr = dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, QOS_CLASS_USER_INITIATED, QOS_MIN_RELATIVE_PRIORITY);
    dispatch_queue_t queue = dispatch_queue_create("EditorViewModel", attr);
    _queue = queue;
}

- (void)initializeWithProgressHandler:(void (^)(NSProgress * _Nonnull progress))progressHandler
                    completionHandler:(EditorServiceCompletionHandler)completionHandler {
    dispatch_async(self.queue, ^{
        [self queue_videoProjectWithCompletionHandler:^(SVVideoProject * _Nullable videoProject, NSError * _Nullable error) {
            if (error) {
                completionHandler(nil, nil, nil, nil, error);
                return;
            }
            
            [self queue_mutableCompositionFromVideoProject:videoProject progressHandler:progressHandler completionHandler:^(AVMutableComposition * _Nullable mutableComposition, NSError * _Nullable error) {
                [videoProject.managedObjectContext performBlock:^{
                    [self contextQueue_finalizeWithComposition:mutableComposition videoProject:videoProject completionHandler:completionHandler];
                }];
            }];
        }];
    });
}

- (void)compositionWithCompletionHandler:(void (^)(AVComposition * _Nullable, AVVideoComposition * _Nullable, NSArray<__kindof EditorRenderElement *> * _Nullable))completionHandler {
    dispatch_async(self.queue, ^{
        completionHandler(self.queue_composition, self.queue_videoComposition, self.queue_renderElements);
    });
}

- (NSProgress *)exportWithCompletionHandler:(void (^)(NSError * _Nullable))completionHandler {
    NSProgress *progress = [self exportToURLWithCompletionHandler:^(NSURL * _Nullable outputURL, NSError * _Nullable error) {
        if (error) {
            completionHandler(error);
            return;
        }
        
        [PHPhotoLibrary.sharedPhotoLibrary performChanges:^{
            [PHAssetChangeRequest creationRequestForAssetFromVideoAtFileURL:outputURL];
        } 
                                        completionHandler:^(BOOL success, NSError * _Nullable error) {
            completionHandler(error);
        }];
    }];
    
    return progress;
}

@end
