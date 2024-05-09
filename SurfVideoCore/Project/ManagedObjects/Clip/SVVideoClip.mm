//
//  SVVideoClip.mm
//  SurfVideo
//
//  Created by Jinwoo Kim on 12/15/23.
//

#import <SurfVideoCore/SVVideoClip.hpp>

@implementation SVVideoClip
@dynamic videoTrack;

+ (NSFetchRequest *)fetchRequest {
    return [NSFetchRequest fetchRequestWithEntityName:@"VideoClip"];
}

@end
