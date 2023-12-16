//
//  SVProjectsManager.mm
//  SurfVideo
//
//  Created by Jinwoo Kim on 12/2/23.
//

#import "SVProjectsManager.hpp"
#import "SVVideoProject.hpp"
#import "SVFootage.hpp"
#import "SVPHAssetFootage.hpp"
#import "SVClip.hpp"
#import "SVVideoClip.hpp"
#import "constants.hpp"

SVProjectsManager::SVProjectsManager() : _isInitialized(false) {
    dispatch_queue_attr_t attr = dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, QOS_CLASS_USER_INITIATED, QOS_MIN_RELATIVE_PRIORITY);
    dispatch_queue_t queue = dispatch_queue_create("SVProjectsManager", attr);
    
    if (_queue) {
        dispatch_release(_queue);
    }
    _queue = queue;
}

SVProjectsManager::~SVProjectsManager() {
    dispatch_release(_queue);
    [_context release];
    [_container release];
}

void SVProjectsManager::initialize(NSError * __autoreleasing * _Nullable error) {
    NSFileManager *fileManager = NSFileManager.defaultManager;
    
    NSURL *applicationSupportURL = [fileManager URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask].firstObject;
    
    NSURL *rootURL = [applicationSupportURL URLByAppendingPathComponent:@"SVProjectsManager" isDirectory:YES];
    
    if (![fileManager fileExistsAtPath:rootURL.path isDirectory:nil]) {
        [fileManager createDirectoryAtURL:rootURL withIntermediateDirectories:YES attributes:nil error:error];
        
        if (*error) {
            NS_VOIDRETURN;
        }
    }
        
    NSURL *containerURL = [[rootURL URLByAppendingPathComponent:@"container" isDirectory:NO] URLByAppendingPathExtension:@"sqlite"];
    
    NSLog(@"%@", containerURL);
    
    NSPersistentStoreDescription *persistentStoreDescription = [[NSPersistentStoreDescription alloc] initWithURL:containerURL];
    NSPersistentContainer *container = [[NSPersistentContainer alloc] initWithName:@"v0" managedObjectModel:v0_managedObjectModel()];
    
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    [container.persistentStoreCoordinator addPersistentStoreWithDescription:persistentStoreDescription completionHandler:^(NSPersistentStoreDescription * _Nonnull description, NSError * _Nullable _error) {
        *error = _error;
        dispatch_semaphore_signal(semaphore);
    }];
    [persistentStoreDescription release];
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    dispatch_release(semaphore);
    
    if (*error) {
        [container release];
        NS_VOIDRETURN;
    }
    
    NSManagedObjectContext *context = container.newBackgroundContext;
    
    [_container release];
    _container = [container retain];
    
    [_context release];
    _context = [context retain];
    
    [container release];
    [context release];
    
    _isInitialized = true;
}

void SVProjectsManager::context(void (^completionHandler)(NSManagedObjectContext * _Nullable context, NSError * _Nullable error)) {
    dispatch_async(_queue, ^{
        if (!_isInitialized) {
            NSError * _Nullable error = nil;
            initialize(&error);
            if (error) {
                completionHandler(nil, error);
                NS_VOIDRETURN;
            }
        }
        
        completionHandler(_context, nil);
    });
}

NSManagedObjectModel * SVProjectsManager::v0_managedObjectModel() {
    NSAttributeDescription *VideoProject_createdDateAttributeDescription = [NSAttributeDescription new];
    VideoProject_createdDateAttributeDescription.attributeType = NSDateAttributeType;
    VideoProject_createdDateAttributeDescription.optional = YES;
    VideoProject_createdDateAttributeDescription.transient = NO;
    VideoProject_createdDateAttributeDescription.name = @"createdDate";
    
    NSRelationshipDescription *VideoProject_mainVideoTrackRelationshipDescription = [NSRelationshipDescription new];
    VideoProject_mainVideoTrackRelationshipDescription.optional = YES;
    VideoProject_mainVideoTrackRelationshipDescription.transient = NO;
    VideoProject_mainVideoTrackRelationshipDescription.name = @"mainVideoTrack";
    VideoProject_mainVideoTrackRelationshipDescription.minCount = 1;
    VideoProject_mainVideoTrackRelationshipDescription.maxCount = 1;
    VideoProject_mainVideoTrackRelationshipDescription.deleteRule = NSCascadeDeleteRule;
    
    NSRelationshipDescription *VideoTrack_videoClipsRelationshipDescription = [NSRelationshipDescription new];
    VideoTrack_videoClipsRelationshipDescription.optional = YES;
    VideoTrack_videoClipsRelationshipDescription.transient = NO;
    VideoTrack_videoClipsRelationshipDescription.name = @"videoClips";
    VideoTrack_videoClipsRelationshipDescription.minCount = 0;
    VideoTrack_videoClipsRelationshipDescription.maxCount = 0;
    VideoTrack_videoClipsRelationshipDescription.deleteRule = NSCascadeDeleteRule;
    
    NSRelationshipDescription *VideoTrack_videoProjectRelationshipDescription = [NSRelationshipDescription new];
    VideoTrack_videoProjectRelationshipDescription.optional = YES;
    VideoTrack_videoProjectRelationshipDescription.transient = NO;
    VideoTrack_videoProjectRelationshipDescription.name = @"videoProject";
    VideoTrack_videoProjectRelationshipDescription.minCount = 1;
    VideoTrack_videoProjectRelationshipDescription.maxCount = 1;
    VideoTrack_videoProjectRelationshipDescription.deleteRule = NSNullifyDeleteRule;
    
    NSRelationshipDescription *Clip_footageRelationshipDescription = [NSRelationshipDescription new];
    Clip_footageRelationshipDescription.optional = YES;
    Clip_footageRelationshipDescription.transient = NO;
    Clip_footageRelationshipDescription.name = @"footage";
    Clip_footageRelationshipDescription.minCount = 1;
    Clip_footageRelationshipDescription.maxCount = 1;
    Clip_footageRelationshipDescription.deleteRule = NSCascadeDeleteRule;
    
    NSRelationshipDescription *videoTrackRelationshipDescription = [NSRelationshipDescription new];
    videoTrackRelationshipDescription.optional = YES;
    videoTrackRelationshipDescription.transient = NO;
    videoTrackRelationshipDescription.name = @"videoTrack";
    videoTrackRelationshipDescription.minCount = 1;
    videoTrackRelationshipDescription.maxCount = 1;
    videoTrackRelationshipDescription.deleteRule = NSNullifyDeleteRule;
    
    NSRelationshipDescription *clipRelationshipDescription = [NSRelationshipDescription new];
    clipRelationshipDescription.optional = YES;
    clipRelationshipDescription.transient = NO;
    clipRelationshipDescription.name = @"clip";
    clipRelationshipDescription.minCount = 1;
    clipRelationshipDescription.maxCount = 1;
    clipRelationshipDescription.deleteRule = NSNullifyDeleteRule;
    
    NSAttributeDescription *assetIdentifierAttributeDescription = [NSAttributeDescription new];
    assetIdentifierAttributeDescription.attributeType = NSStringAttributeType;
    assetIdentifierAttributeDescription.optional = YES;
    assetIdentifierAttributeDescription.transient = NO;
    assetIdentifierAttributeDescription.name = @"assetIdentifier";
    
    NSRelationshipDescription *videoProjectAttributeDescription = [NSRelationshipDescription new];
    videoProjectAttributeDescription.optional = YES;
    videoProjectAttributeDescription.transient = NO;
    videoProjectAttributeDescription.name = @"videoProject";
    videoProjectAttributeDescription.minCount = 0;
    videoProjectAttributeDescription.maxCount = 1;
    
    VideoProject_mainVideoTrackRelationshipDescription.inverseRelationship = videoProjectAttributeDescription;
    footagesAttributeDescription.inverseRelationship = videoProjectAttributeDescription;
    videoProjectAttributeDescription.inverseRelationship = footagesAttributeDescription;
    
    //
    
    NSEntityDescription *videoProjectEntityDescription = [NSEntityDescription new];
    videoProjectEntityDescription.name = @"VideoProject";
    videoProjectEntityDescription.managedObjectClassName = NSStringFromClass(SVVideoProject.class);
    
    NSEntityDescription *phAssetFootageEntityDescription = [NSEntityDescription new];
    phAssetFootageEntityDescription.name = @"PHAssetFootage";
    phAssetFootageEntityDescription.managedObjectClassName = NSStringFromClass(SVPHAssetFootage.class);
    
    NSEntityDescription *footageEntityDescription = [NSEntityDescription new];
    footageEntityDescription.name = @"Footage";
    footageEntityDescription.managedObjectClassName = NSStringFromClass(SVFootage.class);
    footageEntityDescription.abstract = YES;
    footageEntityDescription.subentities = @[phAssetFootageEntityDescription];
    
    //
    
    footagesAttributeDescription.destinationEntity = footageEntityDescription;
    videoProjectAttributeDescription.destinationEntity = videoProjectEntityDescription;
    
    //
    
    videoProjectEntityDescription.properties = @[
        VideoProject_createdDateAttributeDescription,
        footagesAttributeDescription
    ];
    
    phAssetFootageEntityDescription.properties = @[
        assetIdentifierAttributeDescription
    ];
    
    footageEntityDescription.properties = @[
        videoProjectAttributeDescription
    ];
    
    [VideoProject_createdDateAttributeDescription release];
    [footagesAttributeDescription release];
    [assetIdentifierAttributeDescription release];
    [videoProjectAttributeDescription release];
    
    //
    
    NSManagedObjectModel *managedObjectModel = [NSManagedObjectModel new];
    managedObjectModel.entities = @[
        videoProjectEntityDescription,
        phAssetFootageEntityDescription,
        footageEntityDescription
    ];
    
    [videoProjectEntityDescription release];
    [phAssetFootageEntityDescription release];
    [footageEntityDescription release];
    
    return [managedObjectModel autorelease];
}
