//
//  SVAudioTrack.hpp
//  SurfVideo
//
//  Created by Jinwoo Kim on 2/25/24.
//

#import <SurfVideoCore/SVTrack.hpp>

NS_ASSUME_NONNULL_BEGIN

@class SVVideoProject;
@class SVAudioClip;

@interface SVAudioTrack : SVTrack
@property (readonly, nonatomic) int64_t audioClipsCount;
@property (retain, nonatomic) NSOrderedSet<SVAudioClip *> * _Nullable audioClips;
@property (retain, nonatomic) SVVideoProject * _Nullable videoProject;
- (void)insertObject:(SVAudioClip *)value inAudioClipsAtIndex:(NSUInteger)idx;
- (void)removeObjectFromAudioClipsAtIndex:(NSUInteger)idx;
- (void)insertAudioClips:(NSArray<SVAudioClip *> *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeAudioClipsAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInAudioClipsAtIndex:(NSUInteger)idx withObject:(SVAudioClip *)value;
- (void)replaceAudioClipsAtIndexes:(NSIndexSet *)indexes withAudioClips:(NSArray<SVAudioClip *> *)values;
- (void)addAudioClipsObject:(SVAudioClip *)value;
- (void)removeAudioClipsObject:(SVAudioClip *)value;
- (void)addAudioClips:(NSOrderedSet<SVAudioClip *> *)values;
- (void)removeAudioClips:(NSOrderedSet<SVAudioClip *> *)values;

@end

NS_ASSUME_NONNULL_END
