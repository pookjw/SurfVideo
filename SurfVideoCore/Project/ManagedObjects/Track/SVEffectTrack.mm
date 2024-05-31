//
//  SVEffectTrack.mm
//  SurfVideoCore
//
//  Created by Jinwoo Kim on 6/1/24.
//

#import "SVEffectTrack.hpp"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wincomplete-implementation"
@implementation SVEffectTrack
#pragma clang diagnostic pop

@dynamic effects;
@dynamic videoProject;

+ (NSFetchRequest *)fetchRequest {
    return [NSFetchRequest fetchRequestWithEntityName:@"EffectTrack"];
}

@end
