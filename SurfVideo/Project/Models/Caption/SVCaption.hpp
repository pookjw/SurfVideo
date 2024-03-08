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
@property (retain, nonatomic) NSAttributedString * _Nullable attributedString;
@property (retain, nonatomic) NSValue * _Nullable startTimeValue;
@property (retain, nonatomic) NSValue * _Nullable endTimeValue;
@property (retain, nonatomic) SVCaptionTrack *captionTrack;
@end

NS_ASSUME_NONNULL_END
