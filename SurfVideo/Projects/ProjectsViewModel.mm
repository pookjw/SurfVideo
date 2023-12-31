//
//  ProjectsViewModel.mm
//  SurfVideo
//
//  Created by Jinwoo Kim on 12/2/23.
//

#import "ProjectsViewModel.hpp"
#import "constants.hpp"
#import "SVProjectsManager.hpp"
#import "SVPHAssetFootage.hpp"

ProjectsViewModel::ProjectsViewModel(UICollectionViewDiffableDataSource<NSString *, NSManagedObjectID *> *dataSource) 
: _isInitialized(false), _dataSource([dataSource retain]) {
    dispatch_queue_attr_t attr = dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, QOS_CLASS_USER_INITIATED, QOS_MIN_RELATIVE_PRIORITY);
    dispatch_queue_t queue = dispatch_queue_create("ProjectsViewModel", attr);
    
    if (_queue) {
        dispatch_release(_queue);
    }
    _queue = queue;
}

ProjectsViewModel::~ProjectsViewModel() {
    dispatch_release(_queue);
    [_dataSource release];
    [_fetchedResultsController release];
    [_delegate release];
}

void ProjectsViewModel::initialize(std::shared_ptr<ProjectsViewModel> ref, void (^completionHandler)(NSError * _Nullable error)) {
    dispatch_async(ref.get()->_queue, ^{
        if (ref.get()->_isInitialized) {
            completionHandler([NSError errorWithDomain:SurfVideoErrorDomain code:SurfVideoAlreadyInitializedError userInfo:nil]);
            NS_VOIDRETURN;
        }
        
        //
        
        __block NSManagedObjectContext * _Nullable context = nil;
        __block NSError * _Nullable error = nil;
        
        dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
        SVProjectsManager::getInstance().context(^(NSManagedObjectContext * _Nullable _context, NSError * _Nullable _error) {
            if (error) {
                error = [_error retain];
            } else {
                context = [_context retain];
            }
            
            dispatch_semaphore_signal(semaphore);
        });
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
        dispatch_release(semaphore);
        
        [context autorelease];
        [error autorelease];
        
        //
        
        if (error) {
            completionHandler(error);
            NS_VOIDRETURN;
        }
        
        NSFetchRequest<SVVideoProject *> *fetchRequest = [SVVideoProject fetchRequest];
        NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"createdDate" ascending:NO];
        fetchRequest.sortDescriptors = @[sortDescriptor];
        [sortDescriptor release];
        
        NSFetchedResultsController *fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:context sectionNameKeyPath:nil cacheName:nil];
        
        FetchedResultsControllerDelegate *delegate = [FetchedResultsControllerDelegate new];
        delegate.didChangeContentWithSnapshotHandler = ^(NSFetchedResultsController * _Nonnull controller, NSDiffableDataSourceSnapshot<NSString *,NSManagedObjectID *> * _Nonnull snapshot) {
            [ref.get()->_dataSource applySnapshot:snapshot animatingDifferences:YES];
        };
        
        fetchedResultsController.delegate = delegate;
        [fetchedResultsController performFetch:&error];
        
        if (error) {
            [fetchedResultsController release];
            [delegate release];
            completionHandler(error);
            NS_VOIDRETURN;
        }
        
        ref.get()->_fetchedResultsController = [fetchedResultsController retain];
        ref.get()->_delegate = [delegate retain];
        
        [fetchedResultsController release];
        [delegate release];
        
        //
        
        ref.get()->_isInitialized = true;
    });
}

void ProjectsViewModel::createNewVideoProject(NSArray<PHPickerResult *> *results, void (^completionHandler)(SVVideoProject * _Nullable videoProject, NSError * _Nullable error)) {
    SVProjectsManager::getInstance().context(^(NSManagedObjectContext * _Nullable context, NSError * _Nullable error) {
        if (error) {
            completionHandler(nil, error);
            NS_VOIDRETURN;
        }
        
        [context performBlock:^{
            SVVideoProject *videoProject = [[SVVideoProject alloc] initWithContext:context];
            videoProject.createdDate = [NSDate now];
            
            SVVideoTrack *mainVideoTrack = [[SVVideoTrack alloc] initWithContext:context];
            videoProject.mainVideoTrack = mainVideoTrack;
            
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
            
            NSError * _Nullable _error = nil;
            
            [context save:&_error];
            if (_error) {
                [videoProject release];
                completionHandler(nil, error);
                NS_VOIDRETURN;
            }
         
            completionHandler([videoProject autorelease], nil);
        }];
    });
}

void ProjectsViewModel::removeAtIndexPath(std::shared_ptr<ProjectsViewModel> ref, NSIndexPath * _Nonnull indexPath, void (^ _Nullable completionHandler)(NSError * _Nullable error)) {
    dispatch_async(ref.get()->_queue, ^{
        SVVideoProject *videoProject = [ref.get()->_fetchedResultsController objectAtIndexPath:indexPath];
        
        SVProjectsManager::getInstance().context(^(NSManagedObjectContext * _Nullable context, NSError * _Nullable error) {
            if (error) {
                if (completionHandler) {
                    completionHandler(error);
                }
                
                NS_VOIDRETURN;
            }
            
            [context performBlock:^{
                [context deleteObject:videoProject];
                
                NSError * _Nullable error = nil;
                [context save:&error];
                
                if (completionHandler) {
                    completionHandler(error);
                }
            }];
        });
    });
}

void ProjectsViewModel::videoProjectFromObjectID(NSManagedObjectID *objectID, void (^completionHandler)(SVVideoProject * _Nullable result, NSError * _Nullable error)) {
    SVProjectsManager::getInstance().context(^(NSManagedObjectContext * _Nullable context, NSError * _Nullable error) {
        if (error) {
            completionHandler(nil, error);
            NS_VOIDRETURN;
        }
        
        completionHandler([context objectWithID:objectID], error);
    });
}

void ProjectsViewModel::videoProjectAtIndexPath(std::shared_ptr<ProjectsViewModel> ref, NSIndexPath *indexPath, void (^completionHandler)(SVVideoProject * _Nullable result, NSError * _Nullable error)) {
    SVProjectsManager::getInstance().context(^(NSManagedObjectContext * _Nullable context, NSError * _Nullable error) {
        if (error) {
            completionHandler(nil, error);
            NS_VOIDRETURN;
        }
        
        
        completionHandler([ref.get()->_fetchedResultsController objectAtIndexPath:indexPath], error);
    });
}
