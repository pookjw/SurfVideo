//
//  SVTrack.mm
//  SurfVideo
//
//  Created by Jinwoo Kim on 12/15/23.
//

#import <SurfVideoCore/SVTrack.hpp>

@implementation SVTrack

+ (NSFetchRequest *)fetchRequest {
    return [NSFetchRequest fetchRequestWithEntityName:@"Track"];
}

@end
