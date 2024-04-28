//
//  SVLocalFileFootage.mm
//  SurfVideo
//
//  Created by Jinwoo Kim on 2/25/24.
//

#import "SVLocalFileFootage.hpp"

@implementation SVLocalFileFootage
@dynamic lastPathComponent;

+ (NSFetchRequest *)fetchRequest {
    return [NSFetchRequest fetchRequestWithEntityName:@"LocalFileFootage"];
}

@end
