//
//  SVPHAssetFootage.mm
//  SurfVideo
//
//  Created by Jinwoo Kim on 12/6/23.
//

#import <SurfVideoCore/SVPHAssetFootage.hpp>

@implementation SVPHAssetFootage
@dynamic assetIdentifier;

+ (NSFetchRequest *)fetchRequest {
    return [NSFetchRequest fetchRequestWithEntityName:@"PHAssetFootage"];
}

@end
