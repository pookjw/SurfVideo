//
//  SVPHAssetFootage.mm
//  SurfVideo
//
//  Created by Jinwoo Kim on 12/6/23.
//

#import "SVPHAssetFootage.hpp"

@implementation SVPHAssetFootage
@dynamic assetIdentifier;

+ (NSFetchRequest *)fetchRequest {
    return [NSFetchRequest fetchRequestWithEntityName:@"PHAssetFootage"];
}

@end
