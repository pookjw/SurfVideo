//
//  ProjectsViewModel.mm
//  SurfVideo
//
//  Created by Jinwoo Kim on 2/12/24.
//

#import "ProjectsViewModel.hpp"
#import <SurfVideoCore/constants.hpp>
#import <SurfVideoCore/SVProjectsManager.hpp>
#import <SurfVideoCore/SVPHAssetFootage.hpp>
#import <SurfVideoCore/SVImageUtils.hpp>

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
            
            PHFetchResult<PHAsset *> *fetchResults = [PHAsset fetchAssetsWithLocalIdentifiers:@[results[0].assetIdentifier] options:nil];
            
            PHImageRequestOptions *imageRequestOptions = [PHImageRequestOptions new];
            imageRequestOptions.synchronous = NO;
            imageRequestOptions.networkAccessAllowed = YES;
            imageRequestOptions.allowSecondaryDegradedImage = NO;
            
            [PHImageManager.defaultManager requestImageForAsset:fetchResults[0] targetSize:PHImageManagerMaximumSize contentMode:PHImageContentModeDefault options:imageRequestOptions resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
                if (id error = info[PHImageErrorKey]) {
                    completionHandler(nil, error);
                    return;
                }
                
                if (static_cast<NSNumber *>(info[PHImageCancelledKey]).boolValue) {
                    completionHandler(nil, [NSError errorWithDomain:SurfVideoErrorDomain code:SurfVideoUserCancelledError userInfo:nil]);
                    return;
                }
                
                if (static_cast<NSNumber *>(info[PHImageResultIsDegradedKey]).boolValue) {
                    return;
                }
                
                [context performBlock:^{
                    NSMutableArray<NSString *> *assetIdentifiers = [[[NSMutableArray<NSString *> alloc] initWithCapacity:results.count] autorelease];
                    for (PHPickerResult *result in results) {
                        [assetIdentifiers addObject:result.assetIdentifier];
                    }
                    
                    NSError * _Nullable error = nil;
                    NSDictionary<NSString *, SVPHAssetFootage *> *phAssetFootages = [SVProjectsManager.sharedInstance contextQueue_phAssetFootagesFromAssetIdentifiers:assetIdentifiers createIfNeededWithoutSaving:YES managedObjectContext:context error:&error];
                    
                    if (error) {
                        completionHandler(nil, error);
                        return;
                    }
                    SVVideoProject *videoProject = [[SVVideoProject alloc] initWithContext:context];
                    videoProject.createdDate = [NSDate now];
                    videoProject.thumbnailImageTIFFData = [SVImageUtils TIFFDataFromCIImage:[CIImage imageWithCGImage:result.CGImage]];
                    
                    SVVideoTrack *videoTrack = [[SVVideoTrack alloc] initWithContext:context];
                    videoProject.videoTrack = videoTrack;
                    
                    SVAudioTrack *audioTrack = [[SVAudioTrack alloc] initWithContext:context];
                    videoProject.audioTrack = audioTrack;
                    [audioTrack release];
                    
                    SVCaptionTrack *captionTrack = [[SVCaptionTrack alloc] initWithContext:context];
                    videoProject.captionTrack = captionTrack;
                    [captionTrack release];
                    
                    for (NSString *assetIdentifier in assetIdentifiers) {
                        SVVideoClip *videoClip = [[SVVideoClip alloc] initWithContext:context];
                        videoClip.footage = phAssetFootages[assetIdentifier];
                        videoClip.compositionID = [NSUUID UUID];
                        [videoTrack addVideoClipsObject:videoClip];
                        [videoClip release];
                    }
                    
                    [videoTrack release];
                    
                    [context obtainPermanentIDsForObjects:@[videoProject] error:&error];
                    [context save:&error];
                    
                    if (error) {
                        [videoProject release];
                        completionHandler(nil, error);
                        return;
                    }
                    
                    completionHandler([videoProject autorelease], nil);
                }];
            }];
            
            [imageRequestOptions release];
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
