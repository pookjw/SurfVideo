//
//  SVProjectsViewModel.mm
//  SurfVideo
//
//  Created by Jinwoo Kim on 2/12/24.
//

#import <SurfVideoCore/SVProjectsViewModel.hpp>
#import <SurfVideoCore/constants.hpp>
#import <SurfVideoCore/SVProjectsManager.hpp>
#import <SurfVideoCore/SVPHAssetFootage.hpp>
#import <SurfVideoCore/SVImageUtils.hpp>
#import <Photos/Photos.h>

__attribute__((objc_direct_members))
@interface SVProjectsViewModel () <NSFetchedResultsControllerDelegate>
#if TARGET_OS_IPHONE
@property (readonly, nonatomic) UICollectionViewDiffableDataSource<NSString *, NSManagedObjectID *> *dataSource;
#elif TARGET_OS_OSX
@property (readonly, nonatomic) NSCollectionViewDiffableDataSource<NSString *, NSManagedObjectID *> *dataSource;
#endif
@property (readonly, nonatomic) dispatch_queue_t queue;
@property (retain, nonatomic) NSManagedObjectContext * _Nullable managedObjectContext;
@property (retain, nonatomic) NSFetchedResultsController<SVVideoProject *> * _Nullable fetchedResultsController;
@end

@implementation SVProjectsViewModel

@synthesize dataSource = _dataSource;

#if TARGET_OS_IPHONE
- (instancetype)initWithDataSource:(UICollectionViewDiffableDataSource<NSString *,NSManagedObjectID *> *)dataSource {
#elif TARGET_OS_OSX
- (instancetype)initWithDataSource:(NSCollectionViewDiffableDataSource<NSString *,NSManagedObjectID *> *)dataSource {
#endif
    if (self = [super init]) {
        _dataSource = [dataSource retain];
        
        dispatch_queue_attr_t attr = dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, QOS_CLASS_USER_INITIATED, QOS_MIN_RELATIVE_PRIORITY);
        _queue = dispatch_queue_create("ProjectsViewModel", attr);
    }
    
    return self;
}

- (void)dealloc {
    [_dataSource release];
    
    if (_queue) {
        dispatch_release(_queue);
    }
    
    [_managedObjectContext release];
    [_fetchedResultsController release];
    [super dealloc];
}

- (void)initializeWithCompletionHandler:(void (^)(NSError * _Nullable))completionHandler {
    dispatch_async(self.queue, ^{
        [SVProjectsManager.sharedInstance managedObjectContextWithCompletionHandler:^(NSManagedObjectContext * _Nullable managedObjectContext) {
            NSFetchRequest<SVVideoProject *> *fetchRequest = [SVVideoProject fetchRequest];
            NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"createdDate" ascending:NO];
            fetchRequest.sortDescriptors = @[sortDescriptor];
            [sortDescriptor release];
            
            NSFetchedResultsController *fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                                                       managedObjectContext:managedObjectContext
                                                                                                         sectionNameKeyPath:nil
                                                                                                                  cacheName:nil];
            
            fetchedResultsController.delegate = self;
            
            self.managedObjectContext = managedObjectContext;
            self.fetchedResultsController = fetchedResultsController;
            
            [managedObjectContext performBlock:^{
                NSError * _Nullable error = nil;
                [fetchedResultsController performFetch:&error];
                
                if (error) {
                    completionHandler(error);
                    return;
                }
                
                completionHandler(nil);
            }];
            
            [fetchedResultsController release];
        }];
    });
    
}

- (void)createVideoProject:(NSArray<PHPickerResult *> *)results completionHandler:(void (^)(SVVideoProject * _Nullable, NSError * _Nullable))completionHandler {
    if (results.count == 0) {
        completionHandler(nil, [NSError errorWithDomain:SurfVideoErrorDomain code:SurfVideoNoSelectedAsset userInfo:nil]);
        return;
    }
    
    [PHPhotoLibrary requestAuthorizationForAccessLevel:PHAccessLevelReadWrite handler:^(PHAuthorizationStatus status) {
        if ((status != PHAuthorizationStatusAuthorized) && (status != PHAuthorizationStatusLimited)) {
            completionHandler(nil, [NSError errorWithDomain:SurfVideoErrorDomain code:SurfVideoNoPhotoLibraryAuthorization userInfo:nil]);
            return;
        }
        
        dispatch_async(self.queue, ^{
            auto context = self.managedObjectContext;
            
            [context performBlock:^{
                NSError * _Nullable error = nil;
                SVVideoProject * _Nullable videoProject = [SVProjectsManager.sharedInstance contextQueue_createVideoProjectWithPickerResults:results managedObjectContext:context error:&error];
                
                if (error != nil) {
                    completionHandler(nil, error);
                    return;
                }
                
                completionHandler(videoProject, nil);
            }];
        });
    }];
}

- (void)deleteAtIndexPaths:(NSSet<NSIndexPath *> *)indexPaths completionHandler:(void (^)(NSError * _Nullable))completionHandler {
    dispatch_async(self.queue, ^{
        auto context = self.managedObjectContext;
        
        [context performBlock:^{
            for (NSIndexPath *indexPath in indexPaths) {
                SVVideoProject *videoProject = [self.fetchedResultsController objectAtIndexPath:indexPath];
                [context deleteObject:videoProject];
            }
            
            NSError * _Nullable error = nil;
            [context save:&error];
            
            if (completionHandler) {
                completionHandler(error);
            }
        }];
    });
}

- (void)videoProjectsAtIndexPaths:(NSSet<NSIndexPath *> *)indexPaths completionHandler:(void (^)(NSDictionary<NSIndexPath *, SVVideoProject *> * _Nonnull))completionHandler {
    dispatch_async(self.queue, ^{
        auto context = self.managedObjectContext;
        
        [context performBlock:^{
            NSMutableDictionary<NSIndexPath *, SVVideoProject *> *results = [NSMutableDictionary<NSIndexPath *, SVVideoProject *> new];
            
            for (NSIndexPath *indexPath in indexPaths) {
                SVVideoProject * _Nullable videoProject = [self.fetchedResultsController objectAtIndexPath:indexPath];
                if (videoProject) {
                    results[indexPath] = videoProject;
                }
            }
            
            completionHandler([results autorelease]);
        }];
    });
}

- (void)videoProjectAtIndexPath:(NSIndexPath *)indexPath completionHandler:(void (^)(SVVideoProject * _Nullable))completionHandler {
    dispatch_async(self.queue, ^{
        auto context = self.managedObjectContext;
        
        [context performBlock:^{
            completionHandler([self.fetchedResultsController objectAtIndexPath:indexPath]);
        }];
    });
}

- (void)controller:(NSFetchedResultsController *)controller didChangeContentWithSnapshot:(NSDiffableDataSourceSnapshot<NSString *,NSManagedObjectID *> *)snapshot {
    dispatch_async(self.queue, ^{
        [self.dataSource applySnapshot:snapshot animatingDifferences:YES];
    });
}

@end
