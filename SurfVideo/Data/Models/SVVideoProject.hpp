//
//  SVVideoProject.hpp
//  SurfVideo
//
//  Created by Jinwoo Kim on 12/2/23.
//

#import <CoreData/CoreData.h>
#import "SVVideoTrack.hpp"

NS_ASSUME_NONNULL_BEGIN

@interface SVVideoProject : NSManagedObject
@property (copy, nonatomic) NSDate * _Nullable createdDate;
@property (retain, nonatomic) SVVideoTrack * _Nullable mainVideoTrack;
@end

NS_ASSUME_NONNULL_END
