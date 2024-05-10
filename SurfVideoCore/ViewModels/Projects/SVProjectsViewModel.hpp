//
//  SVProjectsViewModel.hpp
//  SurfVideo
//
//  Created by Jinwoo Kim on 2/12/24.
//

#import <CoreData/CoreData.h>
#import <PhotosUI/PhotosUI.h>
#import <SurfVideoCore/SVVideoProject.hpp>
#import <TargetConditionals.h>

#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#elif TARGET_OS_OSX
#import <Cocoa/Cocoa.h>
#endif

NS_ASSUME_NONNULL_BEGIN

@interface SVProjectsViewModel : NSObject
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

#if TARGET_OS_IPHONE
- (instancetype)initWithDataSource:(UICollectionViewDiffableDataSource<NSString *, NSManagedObjectID *> *)dataSource;
#elif TARGET_OS_OSX
- (instancetype)initWithDataSource:(NSCollectionViewDiffableDataSource<NSString *, NSManagedObjectID *> *)dataSource;
#endif

- (void)initializeWithCompletionHandler:(void (^ _Nullable)(NSError * _Nullable error))completionHandler;
- (void)createVideoProject:(NSArray<PHPickerResult *> *)results completionHandler:(void (^ _Nullable)(SVVideoProject * _Nullable videoProject, NSError * _Nullable error))completionHandler;
- (void)deleteAtIndexPaths:(NSSet<NSIndexPath *> *)indexPaths completionHandler:(void (^ _Nullable)(NSError * _Nullable error))completionHandler;
- (void)videoProjectsAtIndexPaths:(NSSet<NSIndexPath *> *)indexPaths completionHandler:(void (^ _Nullable)(NSDictionary<NSIndexPath *, SVVideoProject *> *videoProjects))completionHandler;
@end

NS_ASSUME_NONNULL_END
