//
//  SVVideoTrack.hpp
//  SurfVideo
//
//  Created by Jinwoo Kim on 12/15/23.
//

#import <CoreData/CoreData.h>
#import "SVTrack.hpp"
#import "SVVideoClip.hpp"

NS_ASSUME_NONNULL_BEGIN

@class SVVideoProject;

@interface SVVideoTrack : SVTrack
@property (readonly, nonatomic) int64_t videoClipsCount;
@property (retain, nonatomic) NSOrderedSet<SVVideoClip *> * _Nullable videoClips;
@property (retain, nonatomic) SVVideoProject * _Nullable videoProject;
- (void)insertObject:(SVVideoClip *)value inVideoClipsAtIndex:(NSUInteger)idx;
- (void)removeObjectFromVideoClipsAtIndex:(NSUInteger)idx;
- (void)insertVideoClips:(NSArray<SVVideoClip *> *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeVideoClipsAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInVideoClipsAtIndex:(NSUInteger)idx withObject:(SVVideoClip *)value;
- (void)replaceVideoClipsAtIndexes:(NSIndexSet *)indexes withVideoClips:(NSArray<SVVideoClip *> *)values;
- (void)addVideoClipsObject:(SVVideoClip *)value;
- (void)removeVideoClipsObject:(SVVideoClip *)value;
- (void)addVideoClips:(NSOrderedSet<SVVideoClip *> *)values;
- (void)removeVideoClips:(NSOrderedSet<SVVideoClip *> *)values;
@end

NS_ASSUME_NONNULL_END
