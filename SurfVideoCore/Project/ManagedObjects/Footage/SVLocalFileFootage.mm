//
//  SVLocalFileFootage.mm
//  SurfVideo
//
//  Created by Jinwoo Kim on 2/25/24.
//

#import <SurfVideoCore/SVLocalFileFootage.hpp>

@implementation SVLocalFileFootage
@dynamic fileName;
@dynamic digestSHA256;

+ (NSFetchRequest *)fetchRequest {
    return [NSFetchRequest fetchRequestWithEntityName:@"LocalFileFootage"];
}

@end
