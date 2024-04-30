//
//  SVCaptionTrack.hpp
//  SurfVideo
//
//  Created by Jinwoo Kim on 2/21/24.
//

#import <CoreData/CoreData.h>

NS_ASSUME_NONNULL_BEGIN

@class SVCaption;
@class SVVideoProject;

@interface SVCaptionTrack : NSManagedObject
@property (readonly, nonatomic) int64_t captionsCount;
@property (retain, nonatomic) NSOrderedSet<SVCaption *> * _Nullable captions;
@property (retain, nonatomic) SVVideoProject * _Nullable videoProject;
- (void)insertObject:(SVCaption *)value inCaptionsAtIndex:(NSUInteger)idx;
- (void)removeObjectFromCaptionsAtIndex:(NSUInteger)idx;
- (void)insertCaptions:(NSArray<SVCaption *> *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeCaptionsAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInCaptionsAtIndex:(NSUInteger)idx withObject:(SVCaption *)value;
- (void)replaceCaptionsAtIndexes:(NSIndexSet *)indexes withCaptions:(NSArray<SVCaption *> *)values;
- (void)addCaptionsObject:(SVCaption *)value;
- (void)removeCaptionsObject:(SVCaption *)value;
- (void)addCaptions:(NSOrderedSet<SVCaption *> *)values;
- (void)removeCaptions:(NSOrderedSet<SVCaption *> *)values;
@end

NS_ASSUME_NONNULL_END
