//
//  SVAudioClip.mm
//  SurfVideo
//
//  Created by Jinwoo Kim on 2/25/24.
//

#import <SurfVideoCore/SVAudioClip.hpp>

@implementation SVAudioClip
@dynamic audioTrack;

+ (NSFetchRequest *)fetchRequest {
    return [NSFetchRequest fetchRequestWithEntityName:@"AudioClip"];
}

@end
