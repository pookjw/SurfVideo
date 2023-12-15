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
@property (retain, nonatomic) SVClip * _Nullable clip;
@end

NS_ASSUME_NONNULL_END
