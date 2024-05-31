//
//  SVEffectTrack.hpp
//  SurfVideoCore
//
//  Created by Jinwoo Kim on 6/1/24.
//

#import <CoreData/CoreData.h>

NS_ASSUME_NONNULL_BEGIN

@class SVEffect;
@class SVVideoProject;

@interface SVEffectTrack : NSManagedObject
@property (retain, nonatomic) NSSet<SVEffect *> * _Nullable effects;
@property (retain, nonatomic) SVVideoProject * _Nullable videoProject;

- (void)addEffectsObject:(SVEffect *)value;
- (void)removeEffectsObject:(SVEffect *)value;
- (void)addEffects:(NSSet<SVEffect *> *)values;
- (void)removeEffects:(NSSet<SVEffect *> *)values;
@end

NS_ASSUME_NONNULL_END
