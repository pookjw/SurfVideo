//
//  SVVideoTrack.mm
//  SurfVideo
//
//  Created by Jinwoo Kim on 12/15/23.
//

#import <SurfVideoCore/SVVideoTrack.hpp>

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wincomplete-implementation"
@implementation SVVideoTrack
#pragma clang diagnostic pop

@dynamic videoClipsCount;
@dynamic videoProject;
@dynamic videoClips;

+ (NSFetchRequest *)fetchRequest {
    return [NSFetchRequest fetchRequestWithEntityName:@"VideoTrack"];
}

@end
