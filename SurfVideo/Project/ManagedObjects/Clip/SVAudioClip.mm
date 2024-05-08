//
//  SVAudioClip.mm
//  SurfVideo
//
//  Created by Jinwoo Kim on 2/25/24.
//

#import "SVAudioClip.hpp"

@implementation SVAudioClip
@dynamic audioTrack;

+ (NSFetchRequest *)fetchRequest {
    return [NSFetchRequest fetchRequestWithEntityName:@"AudioClip"];
}

@end
