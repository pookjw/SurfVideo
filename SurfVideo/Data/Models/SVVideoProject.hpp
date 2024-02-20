//
//  SVVideoProject.hpp
//  SurfVideo
//
//  Created by Jinwoo Kim on 12/2/23.
//

#import <CoreData/CoreData.h>

NS_ASSUME_NONNULL_BEGIN

@class SVVideoTrack;
@class SVCaptionTrack;

@interface SVVideoProject : NSManagedObject
@property (copy, nonatomic) NSDate * _Nullable createdDate;
@property (retain, nonatomic) SVVideoTrack * _Nullable mainVideoTrack;
@property (retain, nonatomic) SVCaptionTrack * _Nullable captionTrack;
@end

NS_ASSUME_NONNULL_END
