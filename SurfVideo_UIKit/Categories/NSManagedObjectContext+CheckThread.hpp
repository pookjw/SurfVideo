//
//  NSManagedObjectContext+CheckThread.hpp
//  SurfVideo
//
//  Created by Jinwoo Kim on 5/1/24.
//

#import <CoreData/CoreData.h>

NS_ASSUME_NONNULL_BEGIN

__attribute__((objc_direct_members))
@interface NSManagedObjectContext (CheckThread)
- (BOOL)sv_isThreadOfManagedObjectContext;
- (void)sv_performBlock:(void (^)(void))block;
@end

NS_ASSUME_NONNULL_END
