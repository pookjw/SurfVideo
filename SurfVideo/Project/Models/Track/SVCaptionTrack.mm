//
//  SVCaptionTrack.mm
//  SurfVideo
//
//  Created by Jinwoo Kim on 2/21/24.
//

#import "SVCaptionTrack.hpp"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wincomplete-implementation"
@implementation SVCaptionTrack
#pragma clang diagnostic pop

@dynamic captionsCount;
@dynamic captions;
@dynamic videoProject;

+ (NSFetchRequest *)fetchRequest {
    return [NSFetchRequest fetchRequestWithEntityName:@"CaptionTrack"];
}

@end
