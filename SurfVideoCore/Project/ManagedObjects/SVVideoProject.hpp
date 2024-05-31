//
//  SVVideoProject.hpp
//  SurfVideo
//
//  Created by Jinwoo Kim on 12/2/23.
//

#import <CoreData/CoreData.h>

NS_ASSUME_NONNULL_BEGIN

@class SVVideoTrack;
@class SVAudioTrack;
@class SVCaptionTrack;
@class SVEffectTrack;

@interface SVVideoProject : NSManagedObject
@property (retain, nonatomic) NSData * _Nullable thumbnailImageTIFFData;
@property (copy, nonatomic) NSDate * _Nullable createdDate;
@property (retain, nonatomic) SVVideoTrack * _Nullable videoTrack;
@property (retain, nonatomic) SVAudioTrack * _Nullable audioTrack;
@property (retain, nonatomic) SVCaptionTrack * _Nullable captionTrack;
@property (retain, nonatomic) NSOrderedSet<SVEffectTrack *> * _Nullable effectTracks;
- (void)insertObject:(SVEffectTrack *)value inEffectTracksAtIndex:(NSUInteger)idx;
- (void)removeObjectFromEffectTracksAtIndex:(NSUInteger)idx;
- (void)insertEffectTracks:(NSArray<SVEffectTrack *> *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeEffectTracksAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInEffectTracksAtIndex:(NSUInteger)idx withObject:(SVEffectTrack *)value;
- (void)replaceEffectTracksAtIndexes:(NSIndexSet *)indexes withEffectTracks:(NSArray<SVEffectTrack *> *)values;
- (void)addEffectTracksObject:(SVEffectTrack *)value;
- (void)removeEffectTracksObject:(SVEffectTrack *)value;
- (void)addEffectTracks:(NSOrderedSet<SVEffectTrack *> *)values;
- (void)removeEffectTracks:(NSOrderedSet<SVEffectTrack *> *)values;
@end

NS_ASSUME_NONNULL_END
