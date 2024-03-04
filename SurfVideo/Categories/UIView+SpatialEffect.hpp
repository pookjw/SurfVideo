//
//  UIView+SpatialEffect.h
//  SurfVideo
//
//  Created by Jinwoo Kim on 3/4/24.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

__attribute__((objc_direct_members))
@interface UIView (SpatialEffect)
@property (nonatomic, setter=sv_setSpatialEffect:) BOOL sv_spatialEffect;
@end

NS_ASSUME_NONNULL_END
