//
//  SVPHAssetFootage.hpp
//  SurfVideo
//
//  Created by Jinwoo Kim on 12/6/23.
//

#import <CoreData/CoreData.h>
#import "SVFootage.hpp"

NS_ASSUME_NONNULL_BEGIN

@interface SVPHAssetFootage : SVFootage
@property (copy, nonatomic) NSString *assetIdentifier;
@end

NS_ASSUME_NONNULL_END
