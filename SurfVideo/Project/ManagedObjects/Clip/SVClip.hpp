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
@property (copy, nonatomic) NSUUID * _Nullable compositionID;
@property (retain, nonatomic) SVFootage * _Nullable footage;
@property (copy, nonatomic) NSString * _Nullable name;
@end

NS_ASSUME_NONNULL_END
