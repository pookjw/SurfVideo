//
//  ProjectsViewModel.hpp
//  SurfVideo
//
//  Created by Jinwoo Kim on 2/12/24.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import <PhotosUI/PhotosUI.h>
#import "SVVideoProject.hpp"

NS_ASSUME_NONNULL_BEGIN

__attribute__((objc_direct_members))
@interface ProjectsViewModel : NSObject
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithDataSource:(UICollectionViewDiffableDataSource<NSString *, NSManagedObjectID *> *)dataSource;
- (void)initializeWithCompletionHandler:(void (^ _Nullable)(NSError * _Nullable error))completionHandler;
- (void)createVideoProject:(NSArray<PHPickerResult *> *)results completionHandler:(void (^ _Nullable)(SVVideoProject * _Nullable videoProject, NSError * _Nullable error))completionHandler;
- (void)deleteAtIndexPaths:(NSSet<NSIndexPath *> *)indexPaths completionHandler:(void (^ _Nullable)(NSError * _Nullable error))completionHandler;
- (void)videoProjectsAtIndexPaths:(NSSet<NSIndexPath *> *)indexPaths completionHandler:(void (^ _Nullable)(NSDictionary<NSIndexPath *, SVVideoProject *> *videoProjects))completionHandler;
@end

NS_ASSUME_NONNULL_END
