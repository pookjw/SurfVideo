//
//  SVVideoProject.hpp
//  SurfVideo
//
//  Created by Jinwoo Kim on 12/2/23.
//

#import <CoreData/CoreData.h>
#import "SVFootage.hpp"

NS_ASSUME_NONNULL_BEGIN

@interface SVVideoProject : NSManagedObject
@property (copy, nonatomic) NSDate *createdDate;
@property (retain, nonatomic) NSOrderedSet<SVFootage *> *footages;
- (void)insertObject:(SVFootage *)value inFootagesAtIndex:(NSUInteger)idx;
- (void)removeObjectFromFootagesAtIndex:(NSUInteger)idx;
- (void)insertFootages:(NSArray<SVFootage *> *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeFootagesAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInFootagesAtIndex:(NSUInteger)idx withObject:(SVFootage *)value;
- (void)replaceFootagesAtIndexes:(NSIndexSet *)indexes withFootages:(NSArray<SVFootage *> *)values;
- (void)addFootagesObject:(SVFootage *)value;
- (void)removeFootagesObject:(SVFootage *)value;
- (void)addFootages:(NSOrderedSet<SVFootage *> *)values;
- (void)removeFootages:(NSOrderedSet<SVFootage *> *)values;
@end

NS_ASSUME_NONNULL_END
