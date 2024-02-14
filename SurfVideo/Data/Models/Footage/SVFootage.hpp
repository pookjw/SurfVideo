//
//  SVFootage.hpp
//  SurfVideo
//
//  Created by Jinwoo Kim on 12/6/23.
//

#import <CoreData/CoreData.h>

NS_ASSUME_NONNULL_BEGIN

@class SVClip;
@interface SVFootage : NSManagedObject
@property (readonly, nonatomic) int64_t clipsCount;
@property (nullable, nonatomic, retain) NSSet<SVClip *> *clips;
- (void)addClipsObject:(SVClip *)value;
- (void)removeClipsObject:(SVClip *)value;
- (void)addClips:(NSSet<SVClip *> *)values;
- (void)removeClips:(NSSet<SVClip *> *)values;
@end

NS_ASSUME_NONNULL_END
