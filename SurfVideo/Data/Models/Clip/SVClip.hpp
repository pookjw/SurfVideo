//
//  SVClip.hpp
//  SurfVideo
//
//  Created by Jinwoo Kim on 12/15/23.
//

#import <CoreData/CoreData.h>
#import "SVFootage.hpp"

NS_ASSUME_NONNULL_BEGIN

@interface SVClip : NSManagedObject
@property (retain, nonatomic) SVFootage * _Nullable footage;
@end

NS_ASSUME_NONNULL_END
