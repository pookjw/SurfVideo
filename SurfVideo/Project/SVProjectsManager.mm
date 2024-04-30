//
//  SVProjectsManager.mm
//  SurfVideo
//
//  Created by Jinwoo Kim on 2/12/24.
//

#import "SVProjectsManager.hpp"
#import "SVNSAttributedStringValueTransformer.hpp"
#import "SVNSValueValueTransformer.hpp"
#import "NSManagedObjectModel+SVObjectModel.hpp"

__attribute__((objc_direct_members))
@interface SVProjectsManager ()
@property (retain, readonly, nonatomic) dispatch_queue_t queue;
@property (retain, readonly, nonatomic) NSPersistentContainer * _Nullable queue_persistentContainer;
@property (retain, readonly, nonatomic) NSManagedObjectContext * _Nullable queue_managedObjectContext;
@property (readonly, nonatomic) NSURL *containerURL;
@end

@implementation SVProjectsManager

@synthesize queue_persistentContainer = _queue_persistentContainer;
@synthesize queue_managedObjectContext = _queue_managedObjectContext;

+ (SVProjectsManager *)sharedInstance {
    static dispatch_once_t onceToken;
    static SVProjectsManager *instance;
    
    dispatch_once(&onceToken, ^{
        instance = [SVProjectsManager new];
    });
    
    return instance;
}

- (instancetype)init {
    if (self = [super init]) {
        dispatch_queue_attr_t attr = dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, QOS_CLASS_USER_INITIATED, QOS_MIN_RELATIVE_PRIORITY);
        _queue = dispatch_queue_create("SVProjectsManager", attr);
    }
    
    return self;
}

- (void)dealloc {
    if (_queue) {
        dispatch_release(_queue);
    }
    
    [_queue_persistentContainer release];
    [_queue_managedObjectContext release];
    
    [super dealloc];
}

- (NSURL *)localFileFootagesURL {
    return [[self.containerURL URLByDeletingLastPathComponent] URLByAppendingPathComponent:@"LocalFileFootages"];
}

- (void)managedObjectContextWithCompletionHandler:(void (^)(NSManagedObjectContext * _Nullable))completionHandler {
    dispatch_async(self.queue, ^{
        completionHandler(self.queue_managedObjectContext);
    });
}

- (void)cleanupFootagesWithCompletionHandler:(void (^)(NSInteger cleanedUpFootagesCount, NSError * _Nullable error))completionHandler {
    [self managedObjectContextWithCompletionHandler:^(NSManagedObjectContext * _Nullable managedObjectContext) {
        [managedObjectContext performBlock:^{
            NSFetchRequest<SVFootage *> *fetchReqeust = [SVFootage fetchRequest];
            NSError * _Nullable error = nil;
            NSArray<SVFootage *> *footages = [managedObjectContext executeFetchRequest:fetchReqeust error:&error];
            
            if (error) {
                completionHandler(NSNotFound, error);
                return;
            }
            
            NSFileManager *fileManager = NSFileManager.defaultManager;
            NSURL *fileFootageURLs = self.localFileFootagesURL;
            
            NSMutableArray<NSURL *> * _Nullable unusedFootageURLs = [[[fileManager contentsOfDirectoryAtURL:fileFootageURLs includingPropertiesForKeys:nil options:0 error:&error] mutableCopy] autorelease];
            NSInteger removedCount = 0;
            
            if (error) {
                if (!([error.domain isEqualToString:NSCocoaErrorDomain] && error.code == NSFileReadNoSuchFileError)) {
                    completionHandler(NSNotFound, error);
                    return;
                }
                
                error = nil;
            }
            
            for (SVFootage *footage in footages) {
                if ([footage isKindOfClass:SVPHAssetFootage.class]) {
                    if (footage.clipsCount == 0) {
                        [managedObjectContext deleteObject:footage];
                        removedCount += 1;
                    }
                } else if ([footage isKindOfClass:SVLocalFileFootage.class]) {
                    auto localFileFootage = static_cast<SVLocalFileFootage *>(footage);
                    NSString *lastPathCompoent = localFileFootage.lastPathComponent;
                    __block NSURL * _Nullable fileFootageURL = nil;
                    
                    [unusedFootageURLs enumerateObjectsUsingBlock:^(NSURL * _Nonnull unusedFootageURL, NSUInteger idx, BOOL * _Nonnull stop) {
                        if ([unusedFootageURL.lastPathComponent isEqualToString:lastPathCompoent]) {
                            [unusedFootageURLs removeObjectAtIndex:idx];
                            fileFootageURL = unusedFootageURL;
                            *stop = YES;
                        }
                    }];
                    
                    if (fileFootageURL == nil) {
                        removedCount += 1;
                        [managedObjectContext deleteObject:footage];
                    } else if (footage.clipsCount == 0) {
                        removedCount += 1;
                        
                        [fileManager removeItemAtURL:fileFootageURL error:&error];
                        
                        if (error) {
                            completionHandler(NSNotFound, error);
                            return;
                        }
                        
                        [managedObjectContext deleteObject:footage];
                    }
                }
            }
            
            //
            
            for (NSURL *unusedFootageURL in unusedFootageURLs) {
                [fileManager removeItemAtURL:unusedFootageURL error:&error];
                removedCount += 1;
                
                if (error) {
                    completionHandler(NSNotFound, error);
                    return;
                }
            }
            
            //
            
            [managedObjectContext save:&error];
            
            if (error) {
                completionHandler(NSNotFound, error);
                return;
            }
            
            completionHandler(removedCount, nil);
        }];
    }];
}

- (NSDictionary<NSString *,SVPHAssetFootage *> * _Nullable)contextQueue_phAssetFootagesFromAssetIdentifiers:(NSArray<NSString *> *)assetIdentifiers createIfNeededWithoutSaving:(BOOL)createIfNeededWithoutSaving managedObjectContext:(NSManagedObjectContext *)managedObjectContext error:(NSError * _Nullable * _Nullable)error {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%@ CONTAINS %K" argumentArray:@[assetIdentifiers, @"assetIdentifier"]];
    NSFetchRequest<SVPHAssetFootage *> *fetchRequest = [SVPHAssetFootage fetchRequest];
    fetchRequest.predicate = predicate;
    
    NSArray *fetchedObjects = [managedObjectContext executeFetchRequest:fetchRequest error:error];
    if (*error) {
        return nil;
    }
    
    NSMutableDictionary<NSString *, SVPHAssetFootage *> *phAssetFootages = [NSMutableDictionary<NSString *, SVPHAssetFootage *> new];
    
    for (NSString *assetIdentifier in assetIdentifiers) {
        SVPHAssetFootage * _Nullable phAssetFootage = nil;
        
        for (SVPHAssetFootage *fetchedPHAssetFootage in fetchedObjects) {
            if ([fetchedPHAssetFootage.assetIdentifier isEqualToString:assetIdentifier]) {
                phAssetFootage = fetchedPHAssetFootage;
                break;
            }
        }
        
        if (phAssetFootage == nil && createIfNeededWithoutSaving) {
            phAssetFootage = [[[SVPHAssetFootage alloc] initWithContext:managedObjectContext] autorelease];
            phAssetFootage.assetIdentifier = assetIdentifier;
        }
        
        phAssetFootages[assetIdentifier] = phAssetFootage;
    }
    
    return [phAssetFootages autorelease];
}

- (NSPersistentContainer *)queue_persistentContainer {
    if (auto queue_persistentContainer = _queue_persistentContainer) return queue_persistentContainer;
    
    NSError * _Nullable error = nil;
    NSFileManager *fileManager = NSFileManager.defaultManager;
    NSURL *containerURL = self.containerURL;
    
    NSLog(@"%@", [containerURL path]);
    
    if ([fileManager fileExistsAtPath:containerURL.path isDirectory:nil]) {
        BOOL didReset = [self removeContainer_v0_ifNeededWithError:&error];
        
        if (!didReset) {
            
        }
    } else {
        NSURL *directoryURL = [containerURL URLByDeletingLastPathComponent];
        
        if (![fileManager fileExistsAtPath:directoryURL.path isDirectory:nil]) {
            [fileManager createDirectoryAtURL:directoryURL withIntermediateDirectories:YES attributes:nil error:&error];
        }
        
        assert(!error);
    }
    
    //
    
    NSPersistentStoreDescription *persistentStoreDescription = [[NSPersistentStoreDescription alloc] initWithURL:containerURL];
    persistentStoreDescription.shouldAddStoreAsynchronously = NO;
    persistentStoreDescription.shouldMigrateStoreAutomatically = NO;
    
    NSManagedObjectModel *managedObjectModel_current = [NSManagedObjectModel sv_projectsObjectModel_current];
    NSPersistentContainer *persistentContainer = [[NSPersistentContainer alloc] initWithName:@"ProjectsContainer" managedObjectModel:managedObjectModel_current];
    
    [persistentContainer.persistentStoreCoordinator addPersistentStoreWithDescription:persistentStoreDescription completionHandler:^(NSPersistentStoreDescription * _Nonnull description, NSError * _Nullable _error) {
        assert(!_error);
    }];
    
    [persistentStoreDescription release];
    
    _queue_persistentContainer = [persistentContainer retain];
    return [persistentContainer autorelease];
}

- (NSManagedObjectContext *)queue_managedObjectContext {
    if (auto managedObjectContext = _queue_managedObjectContext) return managedObjectContext;
    
    NSManagedObjectContext *managedObjectContext = [self.queue_persistentContainer newBackgroundContext];
    managedObjectContext.mergePolicy = NSMergeByPropertyStoreTrumpMergePolicy;
    
    _queue_managedObjectContext = [managedObjectContext retain];
    return [managedObjectContext autorelease];
}

- (NSURL *)containerURL {
    NSURL *applicationSupportURL = [NSFileManager.defaultManager URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask].firstObject;
    
    return [[[[applicationSupportURL URLByAppendingPathComponent:@"SurfVideo" isDirectory:YES] URLByAppendingPathComponent:@"SVProjectsManager" isDirectory:YES] URLByAppendingPathComponent:@"container" isDirectory:NO] URLByAppendingPathExtension:@"sqlite"];
}

- (BOOL)removeContainer_v0_ifNeededWithError:(NSError **)error {
    NSDictionary *metdata = [NSPersistentStoreCoordinator metadataForPersistentStoreOfType:NSSQLiteStoreType URL:self.containerURL options:nil error:error];
    
    if (*error) {
        return NO;
    }
    
    NSManagedObjectModel *managedObjectModel_v0 = [NSManagedObjectModel sv_projectsObjectModel_v0];
    
    if (![managedObjectModel_v0 isConfiguration:nil compatibleWithStoreMetadata:metdata]) {
        return NO;
    }
    
    NSLog(@"Detected v0 container - removing the container because the migration is not supported.");
    
    NSFileManager *fileManager = NSFileManager.defaultManager;
    NSURL *directoryURL = [self.containerURL URLByDeletingLastPathComponent];
    
    [fileManager removeItemAtURL:directoryURL error:error];
    if (*error) {
        return NO;
    }
    
    [fileManager createDirectoryAtURL:directoryURL withIntermediateDirectories:YES attributes:nil error:error];
    if (*error) {
        return NO;
    }
    
    return YES;
}

@end
