//
//  SVCaption.mm
//  SurfVideo
//
//  Created by Jinwoo Kim on 2/21/24.
//

#import "SVCaption.hpp"

@implementation SVCaption
@dynamic captionID;
@dynamic attributedString;
@dynamic startTimeValue;
@dynamic endTimeValue;
@dynamic captionTrack;

+ (NSFetchRequest *)fetchRequest {
    return [NSFetchRequest fetchRequestWithEntityName:@"Caption"];
}

@end
