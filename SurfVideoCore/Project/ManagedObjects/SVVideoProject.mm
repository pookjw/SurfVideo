//
//  SVVideoProject.mm
//  SurfVideo
//
//  Created by Jinwoo Kim on 12/2/23.
//

#import <SurfVideoCore/SVVideoProject.hpp>

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wincomplete-implementation"
@implementation SVVideoProject
#pragma clang diagnostic pop
@dynamic thumbnailImageTIFFData;
@dynamic createdDate;
@dynamic videoTrack;
@dynamic audioTrack;
@dynamic captionTrack;
@dynamic effectTracks;

+ (NSFetchRequest *)fetchRequest {
    return [NSFetchRequest fetchRequestWithEntityName:@"VideoProject"];
}

@end
