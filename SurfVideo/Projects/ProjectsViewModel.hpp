//
//  ProjectsViewModel.hpp
//  SurfVideo
//
//  Created by Jinwoo Kim on 12/2/23.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import <PhotosUI/PhotosUI.h>
#import <memory>
#import "SVVideoProject.hpp"
#import "FetchedResultsControllerDelegate.hpp"

NS_ASSUME_NONNULL_BEGIN

class ProjectsViewModel {
public:
    ProjectsViewModel(UICollectionViewDiffableDataSource<NSString *, NSManagedObjectID *> *dataSource);
    ~ProjectsViewModel();
    ProjectsViewModel(const ProjectsViewModel&) = delete;
    ProjectsViewModel& operator=(const ProjectsViewModel&) = delete;
    
    void initialize(std::shared_ptr<ProjectsViewModel> ref, void (^completionHandler)(NSError * _Nullable error));
    void createNewVideoProject(NSArray<PHPickerResult *> *results, void (^completionHandler)(SVVideoProject * _Nullable videoProject, NSError * _Nullable error));
    void videoProjectFromObjectID(NSManagedObjectID *objectID, void (^completionHandler)(SVVideoProject * _Nullable result, NSError * _Nullable error));
    void videoProjectAtIndexPath(std::shared_ptr<ProjectsViewModel> ref, NSIndexPath *indexPath, void (^completionHandler)(SVVideoProject * _Nullable result, NSError * _Nullable error));
private:
    bool _isInitialized;
    const UICollectionViewDiffableDataSource<NSString *, NSManagedObjectID *> *_dataSource;
    dispatch_queue_t _queue;
    NSFetchedResultsController<SVVideoProject *> *_fetchedResultsController;
    FetchedResultsControllerDelegate *_delegate;
};

NS_ASSUME_NONNULL_END
