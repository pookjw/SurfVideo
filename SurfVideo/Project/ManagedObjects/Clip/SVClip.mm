//
//  SVClip.mm
//  SurfVideo
//
//  Created by Jinwoo Kim on 12/15/23.
//

#import "SVClip.hpp"

@implementation SVClip
@dynamic footage;
@dynamic name;

+ (NSFetchRequest *)fetchRequest {
    return [NSFetchRequest fetchRequestWithEntityName:@"Clip"];
}

@end
