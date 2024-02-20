//
//  SVCaption.hpp
//  SurfVideo
//
//  Created by Jinwoo Kim on 2/21/24.
//

#import <CoreData/CoreData.h>

NS_ASSUME_NONNULL_BEGIN

@class SVCaptionTrack;

@interface SVCaption : NSManagedObject
@property (copy, nonatomic) NSAttributedString * _Nullable attributedString;
@property (copy, nonatomic) NSValue * _Nullable startTimeValue;
@property (copy, nonatomic) NSValue * _Nullable endTimeValue;
@property (retain, nonatomic) SVCaptionTrack *captionTrack;
@end

NS_ASSUME_NONNULL_END
