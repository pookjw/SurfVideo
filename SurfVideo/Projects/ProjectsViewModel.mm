//
//  ProjectsViewModel.mm
//  SurfVideo
//
//  Created by Jinwoo Kim on 2/12/24.
//

#import "ProjectsViewModel.hpp"
#import "constants.hpp"
#import "SVProjectsManager.hpp"
#import "SVPHAssetFootage.hpp"

__attribute__((objc_direct_members))
@interface ProjectsViewModel () <NSFetchedResultsControllerDelegate>
@property (readonly, nonatomic) UICollectionViewDiffableDataSource<NSString *, NSManagedObjectID *> *dataSource;
@property (readonly, nonatomic) dispatch_queue_t queue;
@property (retain, nonatomic) NSManagedObjectContext * _Nullable managedObjectContext;
@property (retain, nonatomic) NSFetchedResultsController<SVVideoProject *> * _Nullable fetchedResultsController;
@end

@implementation ProjectsViewModel

@synthesize dataSource = _dataSource;

- (instancetype)initWithDataSource:(UICollectionViewDiffableDataSource<NSString *,NSManagedObjectID *> *)dataSource {
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
            }];
            
            [fetchedResultsController release];
            
        }];
    });
    
}

- (void)createVideoProject:(NSArray<PHPickerResult *> *)results completionHandler:(void (^)(SVVideoProject * _Nullable, NSError * _Nullable))completionHandler {
    dispatch_async(self.queue, ^{
        auto context = self.managedObjectContext;
        
        [context performBlock:^{
            SVVideoProject *videoProject = [[SVVideoProject alloc] initWithContext:context];
            videoProject.createdDate = [NSDate now];
            
            SVVideoTrack *mainVideoTrack = [[SVVideoTrack alloc] initWithContext:context];
            videoProject.mainVideoTrack = mainVideoTrack;
            
            SVCaptionTrack *captionTrack = [[SVCaptionTrack alloc] initWithContext:context];
            videoProject.captionTrack = captionTrack;
            [captionTrack release];
            
            [results enumerateObjectsUsingBlock:^(PHPickerResult * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                SVPHAssetFootage *assetFootage = [[SVPHAssetFootage alloc] initWithContext:context];
                assetFootage.assetIdentifier = obj.assetIdentifier;
                
                SVVideoClip *videoClip = [[SVVideoClip alloc] initWithContext:context];
                videoClip.footage = assetFootage;
                [assetFootage release];
                
                [mainVideoTrack addVideoClipsObject:videoClip];
                [videoClip release];
            }];
            
            [mainVideoTrack release];
            
            NSError * _Nullable error = nil;
            
            [context save:&error];
            if (error) {
                [videoProject release];
                completionHandler(nil, error);
                return;
            }
         
            completionHandler([videoProject autorelease], nil);
        }];
    });
}

- (void)removeAtIndexPath:(NSIndexPath *)indexPath completionHandler:(void (^)(NSError * _Nullable))completionHandler {
    dispatch_async(self.queue, ^{
        auto context = self.managedObjectContext;
        
        [context performBlock:^{
            SVVideoProject *videoProject = [self.fetchedResultsController objectAtIndexPath:indexPath];
            
            [context deleteObject:videoProject];
            
            NSError * _Nullable error = nil;
            [context save:&error];
            
            if (completionHandler) {
                completionHandler(error);
            }
        }];
    });
}

- (void)videoProjectFromObjectID:(NSManagedObjectID *)objectID completionHandler:(void (^)(SVVideoProject * _Nullable))completionHandler {
    dispatch_async(self.queue, ^{
        auto context = self.managedObjectContext;
        
        [context performBlock:^{
            completionHandler([context objectWithID:objectID]);
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
