//
//  SVEffect.hpp
//  SurfVideoCore
//
//  Created by Jinwoo Kim on 6/1/24.
//

#import <CoreData/CoreData.h>

NS_ASSUME_NONNULL_BEGIN

@class SVEffectTrack;

@interface SVEffect : NSManagedObject
@property (copy, nonatomic) NSUUID * _Nullable effectID;
@property (copy, nonatomic) NSString * _Nullable effectName;
@property (retain, nonatomic) NSValue * _Nullable timeRangeValue;
@property (retain, nonatomic) SVEffectTrack * _Nullable effectTrack;
@end

NS_ASSUME_NONNULL_END
