//
//  SVVideoProject.hpp
//  SurfVideo
//
//  Created by Jinwoo Kim on 12/2/23.
//

#import <CoreData/CoreData.h>

NS_ASSUME_NONNULL_BEGIN

@interface SVVideoProject : NSManagedObject
@property (copy, nonatomic) NSDate *createdDate;
@end

NS_ASSUME_NONNULL_END
