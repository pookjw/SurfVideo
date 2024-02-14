//
//  SVProjectsManager.hpp
//  SurfVideo
//
//  Created by Jinwoo Kim on 2/12/24.
//

#import <CoreData/CoreData.h>

NS_ASSUME_NONNULL_BEGIN

__attribute__((objc_direct_members))
@interface SVProjectsManager : NSObject
+ (SVProjectsManager *)sharedInstance;
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
- (void)managedObjectContextWithCompletionHandler:(void (^)(NSManagedObjectContext * _Nullable managedObjectContext))completionHandler;
- (void)cleanupFootagesWithCompletionHandler:(void (^)(NSInteger cleanedUpFootagesCount, NSError * _Nullable error))completionHandler;
@end

NS_ASSUME_NONNULL_END
