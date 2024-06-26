//
//  SVAudioTrack.mm
//  SurfVideo
//
//  Created by Jinwoo Kim on 2/25/24.
//

#import <SurfVideoCore/SVAudioTrack.hpp>

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wincomplete-implementation"
@implementation SVAudioTrack
#pragma clang diagnostic pop

@dynamic audioClipsCount;
@dynamic audioClips;
@dynamic videoProject;

+ (NSFetchRequest *)fetchRequest {
    return [NSFetchRequest fetchRequestWithEntityName:@"AudioTrack"];
}

@end
