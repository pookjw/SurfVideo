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
            return;
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
        return;
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
                return;
            }
        }
        
        completionHandler(_context, nil);
    });
}

NSManagedObjectModel * SVProjectsManager::v0_managedObjectModel() {
    NSAttributeDescription *createdDateAttributeDescription = [NSAttributeDescription new];
    createdDateAttributeDescription.attributeType = NSDateAttributeType;
    createdDateAttributeDescription.optional = NO;
    createdDateAttributeDescription.transient = NO;
    createdDateAttributeDescription.name = @"createdDate";
    
    NSRelationshipDescription *footagesAttributeDescription = [NSRelationshipDescription new];
    footagesAttributeDescription.optional = NO;
    footagesAttributeDescription.transient = NO;
    footagesAttributeDescription.name = @"footages";
    footagesAttributeDescription.minCount = 0;
    footagesAttributeDescription.maxCount = 0;
    
    NSAttributeDescription *assetIdentifierAttributeDescription = [NSAttributeDescription new];
    assetIdentifierAttributeDescription.attributeType = NSStringAttributeType;
    assetIdentifierAttributeDescription.optional = NO;
    assetIdentifierAttributeDescription.transient = NO;
    assetIdentifierAttributeDescription.name = @"assetIdentifier";
    
    NSRelationshipDescription *videoProjectAttributeDescription = [NSRelationshipDescription new];
    videoProjectAttributeDescription.optional = NO;
    videoProjectAttributeDescription.transient = NO;
    videoProjectAttributeDescription.name = @"videoProject";
    videoProjectAttributeDescription.minCount = 0;
    videoProjectAttributeDescription.maxCount = 1;
    
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
        createdDateAttributeDescription,
        footagesAttributeDescription
    ];
    
    phAssetFootageEntityDescription.properties = @[
        assetIdentifierAttributeDescription
    ];
    
    footageEntityDescription.properties = @[
        videoProjectAttributeDescription
    ];
    
    [createdDateAttributeDescription release];
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
