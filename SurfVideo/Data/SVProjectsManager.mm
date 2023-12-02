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
        NSURL *applicationSupportURL = [NSFileManager.defaultManager URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask].firstObject;
        NSURL *rootURL = [applicationSupportURL URLByAppendingPathComponent:@"SVProjectsManager" isDirectory:YES];
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
    NSEntityDescription *entityDescription = [NSEntityDescription new];
    entityDescription.name = @"VideoProject";
    entityDescription.managedObjectClassName = NSStringFromClass(SVVideoProject.class);
    
    //
    
    NSAttributeDescription *createdDateAttributeDescription = [NSAttributeDescription new];
    createdDateAttributeDescription.attributeValueClassName = @"createdDate";
    createdDateAttributeDescription.attributeType = NSDateAttributeType;
    createdDateAttributeDescription.optional = NO;
    createdDateAttributeDescription.transient = NO;
    createdDateAttributeDescription.name = @"createdDate";
    
    //
    
    entityDescription.properties = @[
        createdDateAttributeDescription
    ];
    
    [createdDateAttributeDescription release];
    
    //
    
    NSManagedObjectModel *managedObjectModel = [NSManagedObjectModel new];
    managedObjectModel.entities = @[entityDescription];
    [entityDescription release];
    
    return [managedObjectModel autorelease];
}
