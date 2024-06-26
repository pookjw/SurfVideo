//
//  SVFootage.mm
//  SurfVideo
//
//  Created by Jinwoo Kim on 12/6/23.
//

#import <SurfVideoCore/SVFootage.hpp>

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wincomplete-implementation"
@implementation SVFootage
#pragma clang diagnostic pop

@dynamic clipsCount;
@dynamic clips;

+ (NSFetchRequest *)fetchRequest {
    return [NSFetchRequest fetchRequestWithEntityName:@"Footage"];
}

@end
