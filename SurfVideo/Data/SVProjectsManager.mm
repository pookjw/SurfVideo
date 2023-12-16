//
//  SVProjectsManager.mm
//  SurfVideo
//
//  Created by Jinwoo Kim on 12/2/23.
//

#import "SVProjectsManager.hpp"
#import "SVVideoProject.hpp"
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
    
    //
    
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
    
    //
    
    NSRelationshipDescription *VideoClip_videoTrackRelationshipDescription = [NSRelationshipDescription new];
    VideoClip_videoTrackRelationshipDescription.optional = YES;
    VideoClip_videoTrackRelationshipDescription.transient = NO;
    VideoClip_videoTrackRelationshipDescription.name = @"videoTrack";
    VideoClip_videoTrackRelationshipDescription.minCount = 1;
    VideoClip_videoTrackRelationshipDescription.maxCount = 1;
    VideoClip_videoTrackRelationshipDescription.deleteRule = NSNullifyDeleteRule;
    
    //
    
    NSRelationshipDescription *Clip_footageRelationshipDescription = [NSRelationshipDescription new];
    Clip_footageRelationshipDescription.optional = YES;
    Clip_footageRelationshipDescription.transient = NO;
    Clip_footageRelationshipDescription.name = @"footage";
    Clip_footageRelationshipDescription.minCount = 1;
    Clip_footageRelationshipDescription.maxCount = 1;
    Clip_footageRelationshipDescription.deleteRule = NSCascadeDeleteRule;
    
    //
    
    NSAttributeDescription *PHAsset_assetIdentifierAttributeDescription = [NSAttributeDescription new];
    PHAsset_assetIdentifierAttributeDescription.attributeType = NSStringAttributeType;
    PHAsset_assetIdentifierAttributeDescription.optional = YES;
    PHAsset_assetIdentifierAttributeDescription.transient = NO;
    PHAsset_assetIdentifierAttributeDescription.name = @"assetIdentifier";
    
    NSRelationshipDescription *Footage_clipRelationshipDescription = [NSRelationshipDescription new];
    Footage_clipRelationshipDescription.optional = YES;
    Footage_clipRelationshipDescription.transient = NO;
    Footage_clipRelationshipDescription.name = @"clip";
    Footage_clipRelationshipDescription.minCount = 1;
    Footage_clipRelationshipDescription.maxCount = 1;
    Footage_clipRelationshipDescription.deleteRule = NSNullifyDeleteRule;
    
    //
    
    VideoProject_mainVideoTrackRelationshipDescription.inverseRelationship = VideoTrack_videoProjectRelationshipDescription;
    VideoTrack_videoClipsRelationshipDescription.inverseRelationship = VideoClip_videoTrackRelationshipDescription;
    VideoTrack_videoProjectRelationshipDescription.inverseRelationship = VideoProject_mainVideoTrackRelationshipDescription;
    Clip_footageRelationshipDescription.inverseRelationship = Footage_clipRelationshipDescription;
    VideoClip_videoTrackRelationshipDescription.inverseRelationship = VideoTrack_videoClipsRelationshipDescription;
    Footage_clipRelationshipDescription.inverseRelationship = Clip_footageRelationshipDescription;
    
    //
    
    NSEntityDescription *videoProjectEntityDescription = [NSEntityDescription new];
    videoProjectEntityDescription.name = @"VideoProject";
    videoProjectEntityDescription.managedObjectClassName = NSStringFromClass(SVVideoProject.class);
    
    NSEntityDescription *videoTrackEntityDescription = [NSEntityDescription new];
    videoTrackEntityDescription.name = @"VideoTrack";
    videoTrackEntityDescription.managedObjectClassName = NSStringFromClass(SVVideoTrack.class);
    
    NSEntityDescription *trackEntityDescription = [NSEntityDescription new];
    trackEntityDescription.name = @"Track";
    trackEntityDescription.managedObjectClassName = NSStringFromClass(SVTrack.class);
    trackEntityDescription.abstract = YES;
    trackEntityDescription.subentities = @[videoTrackEntityDescription];
    
    NSEntityDescription *videoClipEntityDescription = [NSEntityDescription new];
    videoClipEntityDescription.name = @"VideoClip";
    videoClipEntityDescription.managedObjectClassName = NSStringFromClass(SVVideoClip.class);
    
    NSEntityDescription *clipEntityDescription = [NSEntityDescription new];
    clipEntityDescription.name = @"Clip";
    clipEntityDescription.managedObjectClassName = NSStringFromClass(SVClip.class);
    clipEntityDescription.abstract = YES;
    clipEntityDescription.subentities = @[videoClipEntityDescription];
    
    NSEntityDescription *phAssetFootageEntityDescription = [NSEntityDescription new];
    phAssetFootageEntityDescription.name = @"PHAssetFootage";
    phAssetFootageEntityDescription.managedObjectClassName = NSStringFromClass(SVPHAssetFootage.class);
    
    NSEntityDescription *footageEntityDescription = [NSEntityDescription new];
    footageEntityDescription.name = @"Footage";
    footageEntityDescription.managedObjectClassName = NSStringFromClass(SVFootage.class);
    footageEntityDescription.abstract = YES;
    footageEntityDescription.subentities = @[phAssetFootageEntityDescription];
    
    //
    
    VideoProject_mainVideoTrackRelationshipDescription.destinationEntity = videoTrackEntityDescription;
    VideoTrack_videoClipsRelationshipDescription.destinationEntity = videoClipEntityDescription;
    VideoTrack_videoProjectRelationshipDescription.destinationEntity = videoProjectEntityDescription;
    VideoClip_videoTrackRelationshipDescription.destinationEntity = videoTrackEntityDescription;
    Clip_footageRelationshipDescription.destinationEntity = footageEntityDescription;
    Footage_clipRelationshipDescription.destinationEntity = clipEntityDescription;
    
    //
    
    videoProjectEntityDescription.properties = @[
        VideoProject_createdDateAttributeDescription,
        VideoProject_mainVideoTrackRelationshipDescription
    ];
    
    videoTrackEntityDescription.properties = @[
        VideoTrack_videoClipsRelationshipDescription,
        VideoTrack_videoProjectRelationshipDescription
    ];
    
    videoClipEntityDescription.properties = @[
        VideoClip_videoTrackRelationshipDescription
    ];
    
    clipEntityDescription.properties = @[
        Clip_footageRelationshipDescription
    ];
    
    phAssetFootageEntityDescription.properties = @[
        PHAsset_assetIdentifierAttributeDescription
    ];
    
    footageEntityDescription.properties = @[
        Footage_clipRelationshipDescription
    ];
    
    //
    
    [VideoProject_createdDateAttributeDescription release];
    [VideoProject_mainVideoTrackRelationshipDescription release];
    [VideoTrack_videoClipsRelationshipDescription release];
    [VideoTrack_videoProjectRelationshipDescription release];
    [VideoClip_videoTrackRelationshipDescription release];
    [Clip_footageRelationshipDescription release];
    [PHAsset_assetIdentifierAttributeDescription release];
    [Footage_clipRelationshipDescription release];
    
    //
    
    NSManagedObjectModel *managedObjectModel = [NSManagedObjectModel new];
    managedObjectModel.entities = @[
        videoProjectEntityDescription,
        videoTrackEntityDescription,
        trackEntityDescription,
        videoClipEntityDescription,
        clipEntityDescription,
        phAssetFootageEntityDescription,
        footageEntityDescription
    ];
    
    [videoProjectEntityDescription release];
    [videoTrackEntityDescription release];
    [trackEntityDescription release];
    [videoClipEntityDescription release];
    [clipEntityDescription release];
    [phAssetFootageEntityDescription release];
    [footageEntityDescription release];
    
    return [managedObjectModel autorelease];
}
