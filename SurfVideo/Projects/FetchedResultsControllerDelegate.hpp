//
//  FetchedResultsControllerDelegate.hpp
//  SurfVideo
//
//  Created by Jinwoo Kim on 12/2/23.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

NS_ASSUME_NONNULL_BEGIN

__attribute__((objc_direct_members))
@interface FetchedResultsControllerDelegate : NSObject <NSFetchedResultsControllerDelegate>
@property (copy, atomic) void (^ _Nullable didChangeContentWithSnapshotHandler)(NSFetchedResultsController *controller, NSDiffableDataSourceSnapshot<NSString *,NSManagedObjectID *> *snapshot);
@end

NS_ASSUME_NONNULL_END
