//
//  SVFootage.hpp
//  SurfVideo
//
//  Created by Jinwoo Kim on 12/6/23.
//

#import <CoreData/CoreData.h>

NS_ASSUME_NONNULL_BEGIN

@class SVVideoProject;
@interface SVFootage : NSManagedObject
@property (retain, nonatomic) SVVideoProject *videoProject;
@end

NS_ASSUME_NONNULL_END
